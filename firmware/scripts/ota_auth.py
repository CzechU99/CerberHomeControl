# Passes the gate's OTA password from include/secrets.development.h to espota,
# so it is kept in one place instead of also living in platformio.ini.
import os
import re

Import("env")  # noqa: F821 - provided by PlatformIO

if env.GetProjectOption("upload_protocol", "") == "espota":  # noqa: F821
    key = env.GetProjectOption("custom_device_key")  # noqa: F821
    secrets_path = os.path.join(
        env.subst("$PROJECT_DIR"), "include", "secrets.development.h"  # noqa: F821
    )

    password = None
    if os.path.isfile(secrets_path):
        with open(secrets_path, encoding="utf-8") as secrets:
            match = re.search(
                r'^#define\s+OTA_PASSWORD_%s\s+"([^"]*)"' % re.escape(key),
                secrets.read(),
                re.MULTILINE,
            )
        if match:
            password = match.group(1)

    if password:
        env.Append(UPLOAD_FLAGS=["--auth=" + password])  # noqa: F821
    else:
        print(
            "Warning: OTA_PASSWORD_%s not found in include/secrets.development.h"
            % key
        )
