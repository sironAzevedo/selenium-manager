#!/bin/bash
set -e

echo "======================================"
echo "   Selenium LITE MODE (manual start)  "
echo "======================================"

echo "[ENTRYPOINT-LITE] Iniciando Xvfb..."
Xvfb :99 -screen 0 1920x1080x24 &
export DISPLAY=:99
sleep 2

echo "[ENTRYPOINT-LITE] Iniciando Fluxbox..."
fluxbox &
sleep 1

echo "[ENTRYPOINT-LITE] Iniciando noVNC..."
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5900 --listen 7900 &
sleep 1

# Corrigir permissões que o Chrome ajusta automaticamente
echo "Fixing permissions..."
sudo chown -R seluser:seluser /home/seluser
sudo chmod -R 777 /home/seluser/Downloads || true
sudo chmod -R 777 /home/seluser || true

echo "[ENTRYPOINT] Iniciando API Flask..."
python3 /opt/scripts/selenium_api.py &
API_PID=$!

echo ""
echo "[OK] Ambiente gráfico iniciado!"
echo "[INFO] Selenium NÃO está iniciado automaticamente."
echo "[INFO] Use:"
echo "    control-selenium start"
echo ""
echo "[INFO] Logs:"
touch /var/log/selenium.log
tail -f /var/log/selenium.log
