# Nome do serviço no docker-compose
SERVICE=selenium_downloader

# Build da imagem
build:
	@echo "==> Buildando imagem..."
	docker compose build --no-cache

# Subir container
up:
	@echo "==> Subindo container..."
	docker compose up -d
	@echo "==> Container ativo. Execute: make status"

# Derrubar container
down:
	@echo "==> Derrubando containers..."
	docker compose down

# Logs gerais do container
logs:
	@echo "==> Logs (Ctrl+C para sair)..."
	docker compose logs -f

# Verificar status do Selenium
status:
	@echo "==> Status do Selenium..."
	docker exec $(SERVICE) control-selenium status

# Iniciar Selenium
start:
	@echo "==> Iniciando Selenium..."
	docker exec $(SERVICE) control-selenium start

# Parar Selenium
stop:
	@echo "==> Parando Selenium..."
	docker exec $(SERVICE) control-selenium stop

# Reiniciar Selenium
restart:
	@echo "==> Reiniciando Selenium..."
	docker exec $(SERVICE) control-selenium restart

# Aguardar Selenium ficar pronto
wait:
	@echo "==> Aguardando Selenium ficar READY..."
	docker exec $(SERVICE) wait-for-selenium

# Iniciar Selenium + esperar ficar pronto
start-all:
	@echo "==> Iniciando Selenium e aguardando readiness..."
	docker exec $(SERVICE) control-selenium start
	docker exec $(SERVICE) wait-for-selenium
	@echo "==> Selenium está pronto para uso!"

# Abrir bash dentro do container
sh:
	@echo "==> Abrindo shell no container..."
	docker exec -it $(SERVICE) bash

# Abrir VNC
vnc:
	@echo "==> Abrindo VNC em http://localhost:7900"
	open http://localhost:7900 || xdg-open http://localhost:7900

# Rodar testes automaticamente (iniciar → esperar → testar → parar)
run-tests:
	@echo "==> Iniciando Selenium..."
	@docker exec $(SERVICE) control-selenium start

	@echo "==> Aguardando readiness..."
	@docker exec $(SERVICE) wait-for-selenium

	@echo "==> Executando Makefile em '$(TESTS_DIR)' (target: $(TEST_TARGET))..."
	@bash -c '\
		set -e; \
		$(MAKE) -C "$(TESTS_DIR)" $(TEST_TARGET); \
		EXIT_CODE=$$?; \
		echo "==> Parando Selenium..."; \
		docker exec $(SERVICE) control-selenium stop || true; \
		exit $$EXIT_CODE \
	'

	@echo "==> Testes concluídos."

# Iniciar API de controle do Selenium
start-api:
	curl -X POST http://localhost:10000/start
	@echo "==> API de controle do Selenium iniciada."

# Parar API de controle do Selenium
stop-api:
	curl -X POST http://localhost:10000/stop
	@echo "==> API de controle do Selenium parada."

# Verificar status da API de controle do Selenium
status-api:
	curl http://localhost:10000/status
