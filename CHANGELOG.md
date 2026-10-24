## v1.2.0 (2026-10-24)

### Feat

- **firmware**: roll back an OTA update that cannot keep Wi-Fi

## v1.1.0 (2026-10-24)

### Feat

- **firmware**: update ESP firmware over Wi-Fi with ArduinoOTA
- show device info on the status page, published by ESPs on demand
- **app**: open gates with a long press to prevent accidental taps
- confirm gate commands with an acknowledgement from the ES
- **app**: reconnect to MQTT automatically and keep saved settings

### Fix

- **firmware**: verify HiveMQ broker certificate instead of setInsecure
- **app**: store MQTT password in secure storage and log only in debug
- **app**: open settings on first launch when MQTT is not configured

### Refactor

- **firmware**: build all gates from one PlatformIO project

## v1.0.0 (2026-10-24)
