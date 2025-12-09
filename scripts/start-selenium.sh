#!/bin/bash
set -e

SELENIUM_JAR="/opt/selenium/selenium-server.jar"
CHROMEDRIVER_PATH="/usr/bin/chromedriver"
CONFIG_FILE="/opt/selenium/config.toml"

if [ ! -f "$SELENIUM_JAR" ]; then
    echo "[ERRO] selenium-server.jar não encontrado em $SELENIUM_JAR"
    exit 1
fi

exec java \
  -Dwebdriver.chrome.driver="$CHROMEDRIVER_PATH" \
  -jar "$SELENIUM_JAR" \
  standalone \
  --enable-managed-downloads true \
  --config "$CONFIG_FILE" \
  --port 4444
