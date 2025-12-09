## Visão geral

Este repositório fornece uma imagem/container Docker que executa um servidor Selenium Standalone Chrome em modo "lite" (não iniciado automaticamente) e expõe uma API mínima em Flask para controlar o processo Selenium on-demand (iniciar, parar, reiniciar, status). O container também inclui VNC (noVNC) para inspeção visual e scripts utilitários para gerenciamento.

Público-alvo: desenvolvedores e engenheiros de QA que precisam de um Selenium controlável via API/Makefile para execuções locais ou CI.

## Contrato da API de controle

Endpoints (API Flask embutida, escuta por padrão na porta 9000):

- POST /start
  - Ação: inicia o processo Selenium se não estiver rodando.
  - Entrada: nenhuma carga esperada.
  - Saída (200 success): JSON com campos: ok (true), message, pid, port, already_running (bool), timestamp.
  - Erro (500): ok=false e campo details com a saída do script.

- POST /stop
  - Ação: para o processo Selenium.
  - Saída (200 success): ok=true, message, pid, stopped (bool), port, timestamp.

- GET /status
  - Ação: consulta o estado do Selenium.
  - Saída: ok=true/false, message, pid (caso exista), uptime_seconds (quando aplicável), port, timestamp.

- POST /restart
  - Ação: executa stop + start e retorna informações combinadas.

Formato geral de resposta: o serviço Flask invoca o script `control-selenium` que sempre retorna JSON textual; a API converte essa saída e reencaminha aos clientes.

Erros esperados: quando o script shell falha ou retorna JSON inválido, a API responde com status 500 e inclui a saída bruta no campo `details`.

## Arquitetura e componentes

- Dockerfile: baseia-se na imagem oficial `selenium/standalone-chrome:4.10.0`. Modifica o image para incluir Python/Flask e os scripts da aplicação.
- scripts/
  - `control-selenium.sh`: script principal de controle que implementa as ações start/stop/status/restart. Mantém PID em `/tmp/selenium.pid` e logs em `/var/log/selenium.log`.
  - `start-selenium.sh`: script que executa o selenium-server.jar com o chromedriver e argumentos necessários.
  - `entrypoint-lite.sh`: entrypoint do container que prepara Xvfb, fluxbox, noVNC e inicia a API Flask (não inicia o Selenium automaticamente).
  - `wait-for-selenium.sh`: utilitário simples que aguarda readiness consultando `http://localhost:4444/status` (observação: o script procura por "ready" no output — ver nota de troubleshooting).
- `app/app.py`: API Flask que expõe endpoints de controle. Chama `/usr/local/bin/control-selenium` (arquivo copiado a partir de `scripts/control-selenium.sh`) e parseia JSON.
- `docker-compose.yml`: exemplo de orquestração para desenvolvimento com portas mapeadas 4444, 7900 (VNC), 9000 (API). Monta volumes para downloads e logs.
- `Makefile` (raiz): atalhos para build/up/start/stop/status/wait/start-all, e integração com área de testes.
- `testes/test_google.py`: teste exemplo em Python usando `selenium.webdriver.Remote` para conectar-se ao endpoint do Selenium.

## Fluxo de execução (normal)

1. Build da imagem: `make build` (executa `docker compose build --no-cache`).
2. Subir container: `make up` (executa `docker compose up -d`). Entrypoint inicia o ambiente gráfico e a API Flask, mas NÃO inicia o Selenium automaticamente.
3. Iniciar Selenium: via API `POST http://localhost:9000/start` ou `make start-selenium` (que executa `docker exec <container> control-selenium start`).
4. Aguardar readiness: `make wait` ou `docker exec <container> wait-for-selenium`.
5. Executar testes/consumidores (ex.: `testes/test_google.py` usando `http://localhost:4444/wd/hub`).
6. Parar Selenium: `POST /stop` ou `make stop-selenium`.

## Como executar localmente (exemplo rápido)

Requisitos: Docker (e docker-compose), Make, portas livres 4444/7900/9000.

1) Build e subir o container:

```bash
make build
make up
```

2) Iniciar Selenium (dentro do container):

```bash
# via API
curl -X POST http://localhost:9000/start

# ou via Make (usa docker exec)
make start-selenium
```

3) Aguardar readiness:

```bash
make wait
```

4) Rodar teste Python de exemplo (local no host):

```bash
# no diretório root do repositório
make run-tests
```

Observação: o `make run-tests` do Makefile principal invoca o Makefile dentro de `testes/` que cria um virtualenv temporário, instala `selenium` e executa `test_google.py`.

## Detalhes importantes dos scripts

- `control-selenium.sh`:
  - Mantém PID em `/tmp/selenium.pid`.
  - Usa `pgrep -f "selenium-server"` como fallback para detectar processos do Selenium caso não haja PID file.
  - Retorna sempre JSON textual com campos: status (running/success/error/stopped), message, pid, port, timestamps e outros metadados.

- `start-selenium.sh`:
  - Chama o jar do Selenium em `/opt/selenium/selenium-server.jar` com `--config /opt/selenium/config.toml` e `--port 4444`.
  - Falhará se o jar não existir (script sai com código != 0).

- `entrypoint-lite.sh`:
  - Inicia Xvfb, fluxbox e noVNC, depois inicia a API Flask em background e em seguida `tail -f /var/log/selenium.log`.
  - Mensagem chave: Selenium NÃO é iniciado automaticamente; controle via API/shell script.

- `wait-for-selenium.sh`:
  - Tenta `curl -s http://localhost:4444/status | grep -q "ready"` até obter sucesso.
  - Nota: o endpoint `/status` do Selenium Standalone (padrão) pode retornar diferentes formatos; se o script `control-selenium` for usado, a string procurada pode não conter "ready". Se encontrar problemas, verifique e ajuste o token de procura.

## Dependências

- Runtime: imagem `selenium/standalone-chrome:4.10.0` (contém Java, Chrome e ChromeDriver).
- Python dentro do container: Flask (instalado via pip no Dockerfile). Versões do `requirements.txt` locais indicam Flask==2.3.3 e requests==2.31.0 (relevantes para desenvolvimento fora do container).
- Testes: `selenium` Python package (instalado dinamicamente no Makefile dos testes).

## Segurança e permissões

- O Dockerfile modifica permissões de `/home/seluser/Downloads` e `/var/log` para 777. Isso facilita operações locais, mas não é recomendado para ambientes de produção por questões de segurança.
- A API Flask não implementa autenticação. Para produção, adicionar autenticação (token, mTLS, rede interna) é obrigatório.

## Observações e edge cases

- PID file stale: `control-selenium.sh` detecta PID inválido e remove o arquivo.
- Selenium iniciado por fora do script: o `status` procura processos com `pgrep -f "selenium-server"`.
- Saída JSON inválida: `app/app.py` tenta parsear a saída do script; em caso de falha retorna um JSON com raw_output e status:error.

Edge cases notáveis:
- Falha ao encontrar `selenium-server.jar` (start-selenium falhará).
- Processos zombie / PID reuse — atenção ao tempo entre start/stop e verificação do PID.
- `wait-for-selenium.sh` pode travar indefinidamente se a string procurada não existir; considere adicionar timeout.

## Troubleshooting rápido

- Logs do container:

```bash
docker compose logs -f
```

- Logs do selenium no container:

```bash
docker exec -it selenium_downloader tail -n 200 /var/log/selenium.log
```

- Verificar status da API de controle:

```bash
curl http://localhost:9000/status
```

- Se `make wait` não retorna: exec no container e inspecione `/var/log/selenium.log` e verifique se o Selenium iniciou corretamente e está escutando na porta 4444.

## Manutenção e possíveis melhorias

- Adicionar autenticação básica à API Flask (token ou auth middleware).
- Trocar o tail -f do entrypoint por um processo supervisor (`tini`, `supervisord`) para gestão do ciclo de vida dos processos.
- Remover chmod 777 e aplicar usuários/grupos adequados para maior segurança.
- Tornar `wait-for-selenium.sh` baseado em health endpoint oficial do Selenium (HTTP 200/JSON) com timeout configurável.
- Incluir testes automatizados de integração que sobem o container em CI (usando GitHub Actions / GitLab CI) e executam o `test_google.py`.

## Locais de interesse no repositório

- `Dockerfile` — construção da imagem.
- `docker-compose.yml` — orquestração de desenvolvimento.
- `app/app.py` — API Flask de controle.
- `scripts/control-selenium.sh` — lógica de start/stop/status/restart.
- `scripts/start-selenium.sh` — comando de execução do selenium-server.
- `scripts/entrypoint-lite.sh` — entrypoint do container.
- `testes/test_google.py` — exemplo de teste funcional com Selenium.

## Resumo de verificação (quality gates)

- Build: não executado automaticamente aqui; as instruções para build estão no `Makefile` (comandos: `make build`, `make up`).
- Lint / Typecheck: não configurados no repositório atual.
- Tests: há um teste funcional (`testes/test_google.py`) que depende do Selenium rodando; não o executei neste ambiente. Para executar localmente, use `make run-tests`.

## Próximos passos recomendados

1. Ajustar `wait-for-selenium.sh` para usar um timeout e validar HTTP 200.
2. Adicionar autenticação na API Flask e limitar exposição de portas em ambientes sensíveis.
3. Adicionar um job de CI que constrói a imagem e executa o teste funcional em um runner com suporte a Docker.

---

DOCUMENTO gerado automaticamente com base na análise do código presente no repositório.
