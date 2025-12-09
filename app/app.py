from flask import Flask, jsonify
import subprocess
import json
from datetime import datetime

app = Flask(__name__)

CONTROL_CMD = "/usr/local/bin/control-selenium"
LOG_FILE = "/var/log/selenium_api.log"
SELENIUM_PORT = 4444
CONTAINER_NAME = "selenium-node-chrome"

def log_message(message):
    """Log de mensagens para debug"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"
    with open(LOG_FILE, "a") as f:
        f.write(log_entry)
    print(log_entry.strip())

    """Log de mensagens para debug"""
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    log_entry = f"[{timestamp}] {message}\n"
    with open(LOG_FILE, "a") as f:
        f.write(log_entry)
    print(log_entry.strip())

def parse_json_output(output):
    """
    Converte output do script shell (texto) em JSON.
    Se falhar, retorna um dicionário com erro.
    """
    try:
        return json.loads(output)
    except Exception:
        return {
            "status": "error",
            "message": "Script retornou JSON inválido",
            "raw_output": output
        }

def run_cmd(action):
    """
    Executa control-selenium e retorna o JSON gerado.
    """
    try:
        result = subprocess.run(
            [CONTROL_CMD, action],
            capture_output=True,
            text=True
        )
        return parse_json_output(result.stdout)
    except Exception as e:
        return {
            "status": "error",
            "message": "Falha ao executar comando",
            "error": str(e)
        }

@app.route("/start", methods=["POST"])
def api_start():
    log_message("Chamando START")

    result = run_cmd("start")
    status = result.get("status")

    if status == "success":
        return jsonify({
            "ok": True,
            "message": result.get("message"),
            "pid": result.get("pid"),
            "port": result.get("port"),
            "already_running": result.get("already_running", False),
            "timestamp": result.get("timestamp")
        }), 200

    return jsonify({
        "ok": False,
        "message": result.get("message", "Erro ao iniciar Selenium"),
        "details": result
    }), 500

@app.route("/stop", methods=["POST"])
def api_stop():
    log_message("Chamando STOP")

    result = run_cmd("stop")
    status = result.get("status")

    if status == "success":
        return jsonify({
            "ok": True,
            "message": result.get("message", "Selenium parado"),
            "pid": result.get("pid"),
            "stopped": result.get("stopped", False),
            "port": result.get("port"),
            "timestamp": result.get("timestamp")
        }), 200

    return jsonify({
        "ok": False,
        "message": result.get("message", "Erro ao parar Selenium"),
        "details": result
    }), 500

@app.route("/status", methods=["GET"])
def api_status():
    log_message("Chamando STATUS")

    result = run_cmd("status")
    status = result.get("status")

    if status in ("running", "success"):
        return jsonify({
            "ok": True,
            "message": result.get("message", "Selenium está rodando"),
            "pid": result.get("pid"),
            "uptime_seconds": result.get("uptime_seconds"),
            "port": result.get("port"),
            "timestamp": result.get("timestamp")
        }), 200

    if status == "stopped":
        return jsonify({
            "ok": False,
            "message": "Selenium está parado",
            "pid": None,
            "port": result.get("port"),
            "timestamp": result.get("timestamp")
        }), 200

    return jsonify({
        "ok": False,
        "message": result.get("message", "Erro ao consultar status"),
        "details": result
    }), 500

@app.route("/restart", methods=["POST"])
def api_restart():
    log_message("Chamando RESTART")

    result = run_cmd("restart")
    status = result.get("status")

    if status == "success":
        return jsonify({
            "ok": True,
            "message": result.get("message", "Selenium reiniciado"),
            "stop_info": result.get("stop_info"),
            "start_info": result.get("start_info"),
            "port": result.get("port"),
            "timestamp": result.get("timestamp")
        }), 200

    return jsonify({
        "ok": False,
        "message": result.get("message", "Erro ao reiniciar Selenium"),
        "details": result
    }), 500

@app.route("/")
def index():
    return jsonify({
        "service": "Selenium On-Demand API",
        "endpoints": {
            "POST /start": "Inicia Selenium",
            "POST /stop": "Para Selenium",
            "GET /status": "Status do Selenium",
            "POST /restart": "Reinicia Selenium"
        }
    })

if __name__ == "__main__":

    log_message("API Flask iniciando na porta 10000...")
        
    # Verificar configuração inicial
    log_message("Verificando configuração inicial...")
    
    result = run_cmd("status")
    status = result.get("status")
    msg = ""
    if status in ("running", "success"):
        msg = "Selenium já está rodando."
    elif status == "stopped":
        msg = "Selenium está parado."
    else:
        msg = "Selenium não está configurado corretamente."
    
    log_message(f"Status inicial: {msg}")
    
    app.run(host="0.0.0.0", port=10000)
