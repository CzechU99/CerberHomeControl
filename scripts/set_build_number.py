"""Sets the Flutter build number (Android versionCode) from the app version.

Run by `cz bump` as a pre-bump hook, so a newer version always gets a higher
build number: 1.2.3 -> version: 1.2.3+10203 (major * 10000 + minor * 100 + patch).

Manual use: python scripts/set_build_number.py 1.2.3
"""

import os
import re
import sys
from pathlib import Path

PUBSPEC = Path(__file__).resolve().parent.parent / "app" / "pubspec.yaml"


def build_number(version: str) -> int:
    match = re.match(r"(\d+)\.(\d+)\.(\d+)", version)
    if not match:
        sys.exit(f"Not a semantic version: {version}")

    major, minor, patch = (int(part) for part in match.groups())
    if minor > 99 or patch > 99:
        sys.exit(f"Minor and patch must be below 100 to fit the scheme: {version}")
    return major * 10000 + minor * 100 + patch


def main() -> None:
    version = os.environ.get("CZ_PRE_NEW_VERSION") or (
        sys.argv[1] if len(sys.argv) > 1 else None
    )
    if not version:
        sys.exit("Usage: python scripts/set_build_number.py <version>")

    with open(PUBSPEC, encoding="utf-8", newline="") as file:
        text = file.read()

    new_line = f"version: {version}+{build_number(version)}"
    text, count = re.subn(r"^version: [^\r\n]*", new_line, text, count=1, flags=re.M)
    if count != 1:
        sys.exit(f"No version line in {PUBSPEC}")

    with open(PUBSPEC, "w", encoding="utf-8", newline="") as file:
        file.write(text)
    print(new_line)


if __name__ == "__main__":
    main()
