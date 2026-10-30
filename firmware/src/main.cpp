// Cerber - gate controller (ESP32 or ESP8266). One firmware for every gate;
// the gate is selected by the PlatformIO environment (see platformio.ini).
// Pulses the relay when "START" arrives on the command topic and reports
// ONLINE / OFFLINE (retained, OFFLINE via Last Will) on the status topic.
// Each command is answered on the ack topic with "OK" (relay on) or
// "BUSY" (pulse already in progress).
// Device info is published on connect and, while the app keeps sending
// requests on the info request topic, every 10 s.
// Firmware can be updated over Wi-Fi (ArduinoOTA) when OTA_PASSWORD is set;
// an update that cannot keep Wi-Fi is rolled back to the previous firmware.

#include <Arduino.h>
#include <ArduinoOTA.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>
#include <time.h>

#if defined(ESP8266)
#include <ESP8266WiFi.h>
#else
#include <Preferences.h>
#include <Update.h>
#include <WiFi.h>
#include <esp_ota_ops.h>
#include <esp_timer.h>
#endif

#include "ca_cert.h"
#include "secrets.h" // credentials live in secrets.development.h (not in the repo)
#include "version.h"

#if !defined(DEVICE_ID) || !defined(DEVICE_KEY) || !defined(DEVICE_LABEL) || !defined(OTA_HOSTNAME)
#error "Build a gate environment from platformio.ini, e.g. pio run -e honda"
#endif

// ===================== DEVICE =====================
// Picks the *_<DEVICE_KEY> credentials, e.g. MQTT_USER_HONDA.
#define CERBER_CONCAT_(a, b) a##b
#define CERBER_CONCAT(a, b) CERBER_CONCAT_(a, b)
#define MQTT_USER CERBER_CONCAT(MQTT_USER_, DEVICE_KEY)
#define MQTT_PASSWORD CERBER_CONCAT(MQTT_PASSWORD_, DEVICE_KEY)
#define OTA_PASSWORD CERBER_CONCAT(OTA_PASSWORD_, DEVICE_KEY)

// Wi-Fi network of this gate: -D WIFI_NETWORK=PRIMARY or SECONDARY
// in platformio.ini, picking WIFI_SSID_<NETWORK> from the secrets.
#ifndef WIFI_NETWORK
#define WIFI_NETWORK PRIMARY
#endif
#define WIFI_SSID CERBER_CONCAT(WIFI_SSID_, WIFI_NETWORK)
#define WIFI_PASSWORD CERBER_CONCAT(WIFI_PASSWORD_, WIFI_NETWORK)

const char* mqtt_client_id = "cerber-" DEVICE_ID;
const char* mqtt_command_topic = "cerber/" DEVICE_ID "/command";
const char* mqtt_status_topic = "cerber/" DEVICE_ID "/status";
const char* mqtt_ack_topic = "cerber/" DEVICE_ID "/ack";
const char* mqtt_info_topic = "cerber/" DEVICE_ID "/info";
const char* mqtt_info_request_topic = "cerber/" DEVICE_ID "/info/request";

const char* ota_hostname = OTA_HOSTNAME;

// Prefix for serial log messages
const char* LOG_TAG = DEVICE_LABEL;

// ===================== PINS =====================
// Can be overridden per gate in platformio.ini (-D RELAY_PIN=...).
#ifndef RELAY_PIN
#if defined(ESP8266)
#define RELAY_PIN 14 // D5
#else
#define RELAY_PIN 26 // ESP32U - safer than GPIO12
#endif
#endif
// Wi-Fi status LED; a gate without one sets -D NO_STATUS_LED.
#if !defined(NO_STATUS_LED) && !defined(LED_PIN)
#define LED_PIN 13
#endif

// Most relay modules are active LOW; boards that switch the relay on HIGH
// set -D RELAY_ACTIVE_HIGH.
#if defined(RELAY_ACTIVE_HIGH)
#define RELAY_ACTIVE HIGH
#define RELAY_INACTIVE LOW
#else
#define RELAY_ACTIVE LOW
#define RELAY_INACTIVE HIGH
#endif

// Relay / contactor pulse length
const unsigned long RELAY_PULSE_MS = 1000;

// ===================== OBJECTS =====================
WiFiClientSecure espClient;
PubSubClient client(espClient);

#if defined(ESP8266)
// BearSSL takes the trusted roots as a parsed certificate list.
BearSSL::X509List mqttCaCert(MQTT_CA_CERT);
#endif

// ===================== STATE =====================
bool relayPulseActive = false;
unsigned long relayOffAt = 0;

unsigned long lastMqttReconnectAttempt = 0;
const unsigned long MQTT_RECONNECT_INTERVAL_MS = 5000;

unsigned long lastWifiReconnectAttempt = 0;
const unsigned long WIFI_RECONNECT_INTERVAL_MS = 10000;

unsigned long wifiLostAt = 0;
const unsigned long WIFI_RESTART_AFTER_MS = 120000; // restart after 2 minutes without Wi-Fi

unsigned long lastInfoAt = 0;
unsigned long lastInfoRequestAt = 0;
bool infoRequested = false;
const unsigned long INFO_INTERVAL_MS = 10000;
const unsigned long INFO_REQUEST_TIMEOUT_MS = 60000; // the app re-requests every 30 s

bool otaStarted = false;

// Firmware installed over OTA runs "on trial" until it stays connected to
// Wi-Fi; otherwise the previous firmware is restored (see OTA TRIAL).
// ESP32 only - the ESP8266 has no second app slot to roll back to.
bool otaTrial = false;
#if defined(ESP32)
Preferences otaPrefs;
unsigned long otaTrialStartedAt = 0;
unsigned long otaTrialWifiSince = 0;
const unsigned long OTA_TRIAL_TIMEOUT_MS = 180000;     // 3 minutes to reach Wi-Fi
const unsigned long OTA_TRIAL_WIFI_STABLE_MS = 30000;  // Wi-Fi must hold for 30 s
const uint8_t OTA_TRIAL_MAX_BOOTS = 3;                 // crash loop protection
#endif

// BearSSL on the ESP8266 checks certificate dates, so MQTT waits for NTP.
const time_t TIME_SYNCED_AFTER = 1700000000;

// ===================== DECLARATIONS =====================
void publishDeviceInfo();
void handleInfoRequest();

// ===================== RELAY =====================
void startRelayPulse() {
  if (relayPulseActive) {
    Serial.println("Pulse already in progress - ignoring command.");
    client.publish(mqtt_ack_topic, "BUSY");
    return;
  }

  Serial.print(LOG_TAG);
  Serial.println(": START - relay on.");
  digitalWrite(RELAY_PIN, RELAY_ACTIVE);

  relayPulseActive = true;
  relayOffAt = millis() + RELAY_PULSE_MS;
  client.publish(mqtt_ack_topic, "OK");
}

void handleRelayPulse() {
  if (relayPulseActive && (long)(millis() - relayOffAt) >= 0) {
    digitalWrite(RELAY_PIN, RELAY_INACTIVE);
    relayPulseActive = false;
    Serial.print(LOG_TAG);
    Serial.println(": pulse finished.");
  }
}

// ===================== STATUS LED =====================
void setStatusLed(bool on) {
#ifdef LED_PIN
  digitalWrite(LED_PIN, on ? HIGH : LOW);
#else
  (void)on; // this gate has no status LED
#endif
}

// ===================== WIFI =====================
void setupWiFi() {
  WiFi.mode(WIFI_STA);
  // No Wi-Fi power saving - important for connection stability.
#if defined(ESP8266)
  WiFi.setSleepMode(WIFI_NONE_SLEEP);
#else
  WiFi.setSleep(false);
#endif
  WiFi.setAutoReconnect(true);
  WiFi.persistent(false);

#if defined(ESP8266)
  // The ESP8266 SDK auto-connects at boot with Wi-Fi settings saved in flash
  // (e.g. by older firmware); a stale password there makes the router reject
  // it and blocks our own WiFi.begin(). Drop that attempt first.
  WiFi.setAutoConnect(false);
  WiFi.disconnect();
  delay(100);
  // 802.11g only: ESP8266 often fails to join ASUS routers in 802.11n mode.
  WiFi.setPhyMode(WIFI_PHY_MODE_11G);
#endif

  Serial.print("Connecting to Wi-Fi: ");
  Serial.println(WIFI_SSID);

  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startAttempt = millis();

  while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 20000) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.println();
    Serial.println("Wi-Fi connected!");
    Serial.print("IP: ");
    Serial.println(WiFi.localIP());
    Serial.print("RSSI: ");
    Serial.println(WiFi.RSSI());

    setStatusLed(true);
    wifiLostAt = 0;
  } else {
    Serial.println();
    Serial.println("Wi-Fi connection failed in setup(). Will keep retrying in loop().");
    setStatusLed(false);
  }
}

void handleWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    setStatusLed(true);
    wifiLostAt = 0;
    return;
  }

  setStatusLed(false);

  if (wifiLostAt == 0) {
    wifiLostAt = millis();
    Serial.println("Wi-Fi lost.");
  }

  if (millis() - lastWifiReconnectAttempt >= WIFI_RECONNECT_INTERVAL_MS) {
    lastWifiReconnectAttempt = millis();

    Serial.println("Reconnecting to Wi-Fi...");
    WiFi.disconnect(false);
    delay(100);
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  }

  // During an OTA trial the trial decides between keeping and rolling back.
  if (!otaTrial && millis() - wifiLostAt >= WIFI_RESTART_AFTER_MS) {
    Serial.println("No Wi-Fi for 2 minutes. Restarting ESP32.");
    delay(1000);
    ESP.restart();
  }
}

// ===================== MQTT =====================
void mqttCallback(char* topic, byte* payload, unsigned int length) {
  String msg;
  msg.reserve(length + 1);

  for (unsigned int i = 0; i < length; i++) {
    msg += (char)payload[i];
  }

  msg.trim();

  Serial.print("MQTT topic: ");
  Serial.println(topic);
  Serial.print("MQTT message: ");
  Serial.println(msg);

  if (strcmp(topic, mqtt_command_topic) == 0 && msg == "START") {
    startRelayPulse();
  } else if (strcmp(topic, mqtt_info_request_topic) == 0) {
    handleInfoRequest();
  }
}

bool reconnectMqttOnce() {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }

#if defined(ESP8266)
  if (time(nullptr) < TIME_SYNCED_AFTER) {
    Serial.println("Waiting for NTP time before connecting to MQTT...");
    return false;
  }
#endif

  Serial.println("Connecting to MQTT...");

  bool connected = client.connect(
    mqtt_client_id,
    MQTT_USER,
    MQTT_PASSWORD,
    mqtt_status_topic,   // Last Will topic
    0,                   // QoS
    true,                // retain
    "OFFLINE"            // Last Will message
  );

  if (connected) {
    Serial.println("MQTT connected.");

    client.subscribe(mqtt_command_topic);
    client.subscribe(mqtt_info_request_topic);

    client.publish(mqtt_status_topic, "ONLINE", true);
    publishDeviceInfo();

    Serial.print("Subscribed to: ");
    Serial.println(mqtt_command_topic);
  } else {
    Serial.print("MQTT error, rc=");
    Serial.println(client.state());
  }

  return connected;
}

void handleMqtt() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  if (client.connected()) {
    client.loop();
    return;
  }

  if (millis() - lastMqttReconnectAttempt >= MQTT_RECONNECT_INTERVAL_MS) {
    lastMqttReconnectAttempt = millis();
    reconnectMqttOnce();
  }
}

// ===================== DEVICE INFO =====================
long long uptimeSeconds() {
#if defined(ESP8266)
  return (long long)(micros64() / 1000000);
#else
  return (long long)(esp_timer_get_time() / 1000000);
#endif
}

void publishDeviceInfo() {
  time_t now = time(nullptr);
  long long epoch = now > TIME_SYNCED_AFTER ? (long long)now : 0; // 0 until NTP sync

  char payload[192];
  snprintf(
    payload,
    sizeof(payload),
    "{\"firmware\":\"%s\",\"rssi\":%d,\"uptime\":%lld,\"ip\":\"%s\",\"time\":%lld}",
    FIRMWARE_VERSION,
    WiFi.RSSI(),
    uptimeSeconds(),
    WiFi.localIP().toString().c_str(),
    epoch
  );

  client.publish(mqtt_info_topic, payload, true);
  lastInfoAt = millis();
}

void handleInfoRequest() {
  bool wasRequested = infoRequested;
  infoRequested = true;
  lastInfoRequestAt = millis();

  if (!wasRequested) {
    publishDeviceInfo();
  }
}

void handleDeviceInfo() {
  if (!infoRequested || !client.connected()) {
    return;
  }

  if (millis() - lastInfoRequestAt >= INFO_REQUEST_TIMEOUT_MS) {
    infoRequested = false;
    return;
  }

  if (millis() - lastInfoAt >= INFO_INTERVAL_MS) {
    publishDeviceInfo();
  }
}

// ===================== OTA TRIAL =====================
#if defined(ESP32)
// The trial is tied to the partition written by OTA, so a later USB upload
// (which boots another partition) never inherits a stale trial.
void startOtaTrial() {
  const esp_partition_t* next = esp_ota_get_boot_partition();

  otaPrefs.begin("ota", false);
  otaPrefs.putString("trial", next->label);
  otaPrefs.putUChar("boots", 0);
  otaPrefs.end();
}

void endOtaTrial() {
  otaPrefs.begin("ota", false);
  otaPrefs.clear();
  otaPrefs.end();
  otaTrial = false;
}

void rollBackFirmware(const char* reason) {
  digitalWrite(RELAY_PIN, RELAY_INACTIVE);
  endOtaTrial();

  Serial.print("New firmware failed (");
  Serial.print(reason);
  Serial.println(").");

  if (Update.canRollBack() && Update.rollBack()) {
    Serial.println("Rolling back to the previous firmware.");
    delay(1000);
    ESP.restart();
  }
  Serial.println("No previous firmware to roll back to - keeping this one.");
}

void beginOtaTrial() {
  otaPrefs.begin("ota", false);
  String trialPartition = otaPrefs.getString("trial", "");
  if (trialPartition.isEmpty()) {
    otaPrefs.end();
    return;
  }
  if (trialPartition != esp_ota_get_running_partition()->label) {
    otaPrefs.end();
    endOtaTrial(); // flashed over USB since the OTA update
    return;
  }

  uint8_t boots = otaPrefs.getUChar("boots", 0) + 1;
  otaPrefs.putUChar("boots", boots);
  otaPrefs.end();

  otaTrial = true;
  otaTrialStartedAt = millis();
  Serial.printf("New firmware on trial (boot %u of %u).\n", boots, OTA_TRIAL_MAX_BOOTS);

  if (boots > OTA_TRIAL_MAX_BOOTS) {
    rollBackFirmware("keeps restarting");
  }
}

void handleOtaTrial() {
  if (!otaTrial) {
    return;
  }

  if (WiFi.status() == WL_CONNECTED) {
    if (otaTrialWifiSince == 0) {
      otaTrialWifiSince = millis();
    }
    if (millis() - otaTrialWifiSince >= OTA_TRIAL_WIFI_STABLE_MS) {
      endOtaTrial();
      Serial.println("New firmware confirmed.");
    }
    return;
  }

  otaTrialWifiSince = 0;
  if (millis() - otaTrialStartedAt >= OTA_TRIAL_TIMEOUT_MS) {
    rollBackFirmware("no Wi-Fi");
  }
}
#else
// The ESP8266 keeps a single app slot, so there is nothing to roll back to.
void startOtaTrial() {}
void beginOtaTrial() {}
void handleOtaTrial() {}
#endif

// ===================== OTA =====================
void startOta() {
  if (strlen(OTA_PASSWORD) == 0) {
    Serial.println("OTA disabled - set OTA_PASSWORD_" DEVICE_LABEL " in secrets.development.h.");
    otaStarted = true; // do not retry
    return;
  }

  ArduinoOTA.setHostname(ota_hostname);
  ArduinoOTA.setPassword(OTA_PASSWORD);

  ArduinoOTA.onStart([]() {
    // Never leave the gate relay on while flashing.
    digitalWrite(RELAY_PIN, RELAY_INACTIVE);
    relayPulseActive = false;
    Serial.println("OTA update started.");
  });
  ArduinoOTA.onEnd([]() {
    startOtaTrial();
    Serial.println("OTA update finished, restarting.");
  });
  ArduinoOTA.onError([](ota_error_t error) {
    Serial.print("OTA error: ");
    Serial.println(error);
  });

  ArduinoOTA.begin();
  otaStarted = true;

  Serial.print("OTA ready as ");
  Serial.println(ota_hostname);
}

void handleOta() {
  if (WiFi.status() != WL_CONNECTED) {
    return;
  }

  // ArduinoOTA needs a working network, so it starts on the first connection.
  if (!otaStarted) {
    startOta();
  }

  ArduinoOTA.handle();
}

// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  delay(500);

  // Set the idle level before enabling the output, so the relay never
  // blips on during boot.
  digitalWrite(RELAY_PIN, RELAY_INACTIVE);
  pinMode(RELAY_PIN, OUTPUT);

#ifdef LED_PIN
  pinMode(LED_PIN, OUTPUT);
#endif
  setStatusLed(false);

  beginOtaTrial();
  setupWiFi();
  configTime(0, 0, "pool.ntp.org", "time.google.com");

#if defined(ESP8266)
  espClient.setTrustAnchors(&mqttCaCert);
#else
  espClient.setCACert(MQTT_CA_CERT);
#endif

  client.setServer(MQTT_HOST, MQTT_PORT);
  client.setCallback(mqttCallback);
  client.setKeepAlive(15);
  client.setSocketTimeout(5);
}

// ===================== LOOP =====================
void loop() {
  handleWiFi();
  handleOtaTrial();
  handleOta();
  handleMqtt();
  handleRelayPulse();
  handleDeviceInfo();
}
