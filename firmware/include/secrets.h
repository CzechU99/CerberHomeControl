#pragma once

// Credentials template - this file IS committed, so keep the values empty.
// Put the real values in secrets.development.h in this folder
// (it is git-ignored). If that file exists, it is used automatically.
// Per-gate values end with the DEVICE_KEY from platformio.ini.
// Each gate picks a Wi-Fi network with WIFI_NETWORK in platformio.ini.

#if __has_include("secrets.development.h")
#include "secrets.development.h"
#else
#define WIFI_SSID_PRIMARY       ""
#define WIFI_PASSWORD_PRIMARY   ""

#define WIFI_SSID_SECONDARY     ""
#define WIFI_PASSWORD_SECONDARY ""

#define MQTT_HOST     ""
#define MQTT_PORT     8883

// Empty OTA_PASSWORD_* = OTA disabled for that gate
#define MQTT_USER_HONDA         ""
#define MQTT_PASSWORD_HONDA     ""
#define OTA_PASSWORD_HONDA      ""

#define MQTT_USER_HYUNDAI       ""
#define MQTT_PASSWORD_HYUNDAI   ""
#define OTA_PASSWORD_HYUNDAI    ""

#define MQTT_USER_TOYOTA        ""
#define MQTT_PASSWORD_TOYOTA    ""
#define OTA_PASSWORD_TOYOTA     ""

#define MQTT_USER_MAIN_GATE     ""
#define MQTT_PASSWORD_MAIN_GATE ""
#define OTA_PASSWORD_MAIN_GATE  ""
#endif
