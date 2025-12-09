#!/bin/bash
ACTION=$1

START_SCRIPT="/opt/bin/start-selenium.sh"
PID_FILE="/tmp/selenium.pid"
LOG_FILE="/var/log/selenium.log"
PORT=4444

json() {
    echo "$1" | sed 's/^[ ]*//'
}

start_selenium() {
    START_TIME=$(date +%s)

    # Já está rodando?
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            json "{
                \"status\": \"success\",
                \"message\": \"Selenium já estava em execução\",
                \"pid\": $pid,
                \"port\": $PORT,
                \"log\": \"$LOG_FILE\",
                \"already_running\": true,
                \"timestamp\": \"$(date -Iseconds)\"
            }"
            return 0
        fi
    fi

    rm -f "$PID_FILE"

    # Iniciar Selenium
    $START_SCRIPT >> "$LOG_FILE" 2>&1 &
    pid=$!
    echo $pid > "$PID_FILE"

    sleep 1

    # Verifica se iniciou
    if ! kill -0 "$pid" 2>/dev/null; then
        json "{
            \"status\": \"error\",
            \"message\": \"Falha ao iniciar Selenium\",
            \"pid\": null,
            \"port\": $PORT,
            \"log\": \"$LOG_FILE\",
            \"timestamp\": \"$(date -Iseconds)\"
        }"
        return 1
    fi

    END_TIME=$(date +%s)
    INIT_TIME=$((END_TIME - START_TIME))

    json "{
        \"status\": \"success\",
        \"message\": \"Selenium iniciado com sucesso\",
        \"pid\": $pid,
        \"port\": $PORT,
        \"startup_time_seconds\": $INIT_TIME,
        \"already_running\": false,
        \"log\": \"$LOG_FILE\",
        \"timestamp\": \"$(date -Iseconds)\"
    }"
}

stop_selenium() {
    START_TIME=$(date +%s)

    # verificar PID
    if [ ! -f "$PID_FILE" ]; then
        json "{
            \"status\": \"success\",
            \"message\": \"Selenium já estava parado\",
            \"stopped\": false,
            \"pid\": null,
            \"port\": $PORT,
            \"timestamp\": \"$(date -Iseconds)\"
        }"
        return 0
    fi

    pid=$(cat "$PID_FILE")

    if ! kill -0 "$pid" 2>/dev/null; then
        rm -f "$PID_FILE"
        json "{
            \"status\": \"success\",
            \"message\": \"PID inválido removido\",
            \"stopped\": false,
            \"pid\": null,
            \"port\": $PORT,
            \"timestamp\": \"$(date -Iseconds)\"
        }"
        return 0
    fi

    kill "$pid"

    rm -f "$PID_FILE"

    END_TIME=$(date +%s)
    STOP_TIME=$((END_TIME - START_TIME))

    json "{
        \"status\": \"success\",
        \"message\": \"Selenium parado com sucesso\",
        \"stopped\": true,
        \"pid\": $pid,
        \"port\": $PORT,
        \"shutdown_time_seconds\": $STOP_TIME,
        \"timestamp\": \"$(date -Iseconds)\"
    }"
}

status_selenium() {
    # Se existe PID file
    if [ -f "$PID_FILE" ]; then
        pid=$(cat "$PID_FILE")
        if kill -0 "$pid" 2>/dev/null; then
            UPTIME=$(ps -o etimes= -p "$pid" 2>/dev/null | xargs)

            json "{
                \"status\": \"running\",
                \"message\": \"Selenium está em execução\",
                \"pid\": $pid,
                \"uptime_seconds\": $UPTIME,
                \"port\": $PORT,
                \"timestamp\": \"$(date -Iseconds)\"
            }"
            return 0
        else
            json "{
                \"status\": \"error\",
                \"message\": \"PID file existe mas processo não existe\",
                \"pid\": $pid,
                \"port\": $PORT,
                \"timestamp\": \"$(date -Iseconds)\"
            }"
            return 1
        fi
    fi

    # Checar se está rodando sem PID file
    pid=$(pgrep -f "selenium-server" | head -n 1)
    if [ -n "$pid" ]; then
        UPTIME=$(ps -o etimes= -p "$pid" | xargs)

        json "{
            \"status\": \"running\",
            \"message\": \"Selenium está rodando sem PID file\",
            \"pid\": $pid,
            \"uptime_seconds\": $UPTIME,
            \"port\": $PORT,
            \"timestamp\": \"$(date -Iseconds)\"
        }"
        return 0
    fi

    json "{
        \"status\": \"stopped\",
        \"message\": \"Selenium está parado\",
        \"pid\": null,
        \"port\": $PORT,
        \"timestamp\": \"$(date -Iseconds)\"
    }"
}

restart_selenium() {
    STOP_JSON=$(stop_selenium)
    START_JSON=$(start_selenium)

    json "{
        \"status\": \"success\",
        \"message\": \"Selenium reiniciado com sucesso\",
        \"port\": $PORT,
        \"stop_info\": $STOP_JSON,
        \"start_info\": $START_JSON,
        \"timestamp\": \"$(date -Iseconds)\"
    }"
}

case "$ACTION" in
    start) start_selenium ;;
    stop) stop_selenium ;;
    restart) restart_selenium ;;
    status) status_selenium ;;
    *)
        json "{
            \"status\": \"error\",
            \"message\": \"Uso inválido\",
            \"valid_actions\": [\"start\", \"stop\", \"status\", \"restart\"]
        }"
    ;;
esac
