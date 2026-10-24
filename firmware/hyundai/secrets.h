#pragma once

// Credentials template - this file IS committed, so keep the values empty.
// Put the real values in secrets.development.h in this folder
// (it is git-ignored). If that file exists, it is used automatically.

#if __has_include("secrets.development.h")
#include "secrets.development.h"
#else
#define WIFI_SSID     ""
#define WIFI_PASSWORD ""

#define MQTT_HOST     ""
#define MQTT_PORT     8883
#define MQTT_USER     ""
#define MQTT_PASSWORD ""

#define OTA_PASSWORD  ""  // empty = OTA disabled
#endif
