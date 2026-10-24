// Cerber - Hyundai garage gate controller (ESP32).
// Pulses the relay when "START" arrives on the command topic and reports
// ONLINE / OFFLINE (retained, OFFLINE via Last Will) on the status topic.
// Each command is answered on the ack topic with "OK" (relay on) or
// "BUSY" (pulse already in progress).

#include <WiFi.h>
#include <PubSubClient.h>
#include <WiFiClientSecure.h>
#include "secrets.h" // credentials live in secrets.development.h (not in the repo)
#include "ca_cert.h"

// ===================== DEVICE =====================
const char* mqtt_client_id = "cerber-hyundai";
const char* mqtt_command_topic = "cerber/hyundai/command";
const char* mqtt_status_topic = "cerber/hyundai/status";
const char* mqtt_ack_topic = "cerber/hyundai/ack";

// Prefix for serial log messages
const char* LOG_TAG = "HYUNDAI";

// ===================== PINS =====================
// ESP32U - safer than GPIO12
#define RELAY_PIN 26
#define LED_PIN 13

// Most relay modules are active LOW
#define RELAY_ACTIVE LOW
#define RELAY_INACTIVE HIGH

// Relay / contactor pulse length
const unsigned long RELAY_PULSE_MS = 1000;

// ===================== OBJECTS =====================
WiFiClientSecure espClient;
PubSubClient client(espClient);

// ===================== STATE =====================
bool relayPulseActive = false;
unsigned long relayOffAt = 0;

unsigned long lastMqttReconnectAttempt = 0;
const unsigned long MQTT_RECONNECT_INTERVAL_MS = 5000;

unsigned long lastWifiReconnectAttempt = 0;
const unsigned long WIFI_RECONNECT_INTERVAL_MS = 10000;

unsigned long wifiLostAt = 0;
const unsigned long WIFI_RESTART_AFTER_MS = 120000; // restart after 2 minutes without Wi-Fi

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

// ===================== WIFI =====================
void setupWiFi() {
  WiFi.mode(WIFI_STA);
  WiFi.setSleep(false);          // important for ESP32 Wi-Fi stability
  WiFi.setAutoReconnect(true);
  WiFi.persistent(false);

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

    digitalWrite(LED_PIN, HIGH);
    wifiLostAt = 0;
  } else {
    Serial.println();
    Serial.println("Wi-Fi connection failed in setup(). Will keep retrying in loop().");
    digitalWrite(LED_PIN, LOW);
  }
}

void handleWiFi() {
  if (WiFi.status() == WL_CONNECTED) {
    digitalWrite(LED_PIN, HIGH);
    wifiLostAt = 0;
    return;
  }

  digitalWrite(LED_PIN, LOW);

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

  if (millis() - wifiLostAt >= WIFI_RESTART_AFTER_MS) {
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
  }
}

bool reconnectMqttOnce() {
  if (WiFi.status() != WL_CONNECTED) {
    return false;
  }

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

    client.publish(mqtt_status_topic, "ONLINE", true);

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

// ===================== SETUP =====================
void setup() {
  Serial.begin(115200);
  delay(500);

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, RELAY_INACTIVE);

  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);

  setupWiFi();

  espClient.setCACert(MQTT_CA_CERT);

  client.setServer(MQTT_HOST, MQTT_PORT);
  client.setCallback(mqttCallback);
  client.setKeepAlive(15);
  client.setSocketTimeout(5);
}

// ===================== LOOP =====================
void loop() {
  handleWiFi();
  handleMqtt();
  handleRelayPulse();
}
