# Caminho da venv temporária
VENV_PATH=.venv_tmp

# Caminho do arquivo de teste
TEST_FILE=test_google.py

# Lista de libs necessárias
PY_DEPS=selenium

# Criar venv temporária
venv:
	@echo "==> Criando venv temporária..."
	python3 -m venv $(VENV_PATH)
	@echo "==> Instalando dependências..."
	$(VENV_PATH)/bin/pip install --upgrade pip
	$(VENV_PATH)/bin/pip install $(PY_DEPS)

# Executar teste dentro da venv
run: venv
	@echo "==> Executando teste Python..."
	$(VENV_PATH)/bin/python3 $(TEST_FILE)

# Remover venv temporária
clean:
	@echo "==> Removendo venv temporária..."
	rm -rf $(VENV_PATH)
	@echo "==> venv removida!"

# Criar venv, rodar teste e apagar tudo
run-clean: run clean
	@echo "==> Execução finalizada e ambiente limpo!"
