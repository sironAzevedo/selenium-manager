# Selenium Standalone Chrome (base)
FROM selenium/standalone-chrome:4.10.0

USER root

# Instalar ferramentas úteis
RUN apt-get update && apt-get install -y \
    curl \
    python3 python3-pip python3-venv \
    procps \
    x11-utils \
    net-tools \
    psmisc \
    && rm -rf /var/lib/apt/lists/*

# Criar diretórios necessários
RUN mkdir -p /home/seluser/Downloads \
    && chmod -R 777 /home/seluser/Downloads \
    && chmod -R 777 /var/log \
    && chown -R seluser:seluser /home/seluser

# ====== COPIAR SCRIPTS ======
COPY scripts/start-selenium.sh /opt/bin/start-selenium.sh
COPY scripts/control-selenium.sh /usr/local/bin/control-selenium
COPY scripts/entrypoint-lite.sh /opt/entrypoint-lite.sh
COPY scripts/wait-for-selenium.sh /usr/local/bin/wait-for-selenium
COPY app/app.py /opt/scripts/selenium_api.py

RUN chmod +x /opt/bin/start-selenium.sh \
    && chmod +x /usr/local/bin/control-selenium \
    && chmod +x /opt/entrypoint-lite.sh \
    && chmod +x /usr/local/bin/wait-for-selenium \
    && chmod +x /opt/scripts/selenium_api.py

# ====== IMPORTANTE ======
# Remover entrypoint original APENAS do Selenium (para não ligar automaticamente)
# MAS manter o ambiente Chrome + VNC funcionando
RUN rm -f /opt/bin/start-selenium-standalone.sh || true
RUN pip3 install flask

# ========= ENTRYPOINT =========
ENTRYPOINT ["/opt/entrypoint-lite.sh"]

# Expor portas
EXPOSE 4444 7900 10000

USER seluser
WORKDIR /home/seluser
# Fim do Dockerfile