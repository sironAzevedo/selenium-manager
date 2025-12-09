#!/bin/bash

echo "[WAIT] Aguardando Selenium..."
until curl -s http://localhost:4444/status | grep -q "ready"; do
    sleep 1
done

echo "[WAIT] Selenium está pronto!"
