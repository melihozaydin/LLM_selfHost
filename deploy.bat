@echo off
SETLOCAL

:: Clean setup
::podman system prune --all

echo --------------
echo CONFIGURATIONS
echo --------------

REM Set the path to the volumes
SET CONF_ROOT=./service-configs
echo CONF_ROOT: %CONF_ROOT%
echo ***
SET OLLAMA_VOLUME=%CONF_ROOT%/ollama
echo OLLAMA_VOLUME: %OLLAMA_VOLUME%

SET OLLAMA_PORT_INTERNAL=11434
echo OLLAMA_PORT_INTERNAL: %OLLAMA_PORT_INTERNAL%
SET OLLAMA_PORT_HOST=7869
echo OLLAMA_PORT_HOST: %OLLAMA_PORT_HOST%
echo ***
SET OLLAMA_WEBUI_VOLUME=%CONF_ROOT%/ollama-webui
echo OLLAMA_WEBUI_VOLUME: %OLLAMA_WEBUI_VOLUME%

SET WEBUI_PORT_INTERNAL=8080
echo WEBUI_PORT_INTERNAL: %WEBUI_PORT_INTERNAL%
SET WEBUI_PORT_HOST=8087
echo WEBUI_PORT_HOST: %WEBUI_PORT_HOST%
echo ***
SET SEARXNG_VOLUME=%CONF_ROOT%/searxng
echo SEARXNG_VOLUME: %SEARXNG_VOLUME%

SET SEARXNG_PORT_INTERNAL=8080
echo SEARXNG_PORT_INTERNAL: %SEARXNG_PORT_INTERNAL%
SET SEARXNG_PORT_HOST=8085
echo SEARXNG_PORT_HOST: %SEARXNG_PORT_HOST%
echo ***
SET N8N_VOLUME=%CONF_ROOT%/n8n
echo N8N_VOLUME: %N8N_VOLUME%

echo ------------
echo Create container network
echo ------------

SET NETWORK_NAME=ollama-docker
echo NETWORK_NAME: %NETWORK_NAME%

podman network create %NETWORK_NAME%

echo ------------
echo Run the Ollama WebUI service
echo ------------

REM Run the Ollama WebUI service --add-host host.docker.internal:host-gateway ^
REM   -e OLLAMA_BASE_URLS=http://host.docker.internal:7869 ^
REM PORT FORWARDİNG ISSUE ON LAN : https://github.com/containers/podman/issues/17030
REM 	https://learn.microsoft.com/en-us/windows/wsl/networking#accessing-a-wsl-2-distribution-from-your-local-area-network-lan
REM netsh interface portproxy add v4tov4 listenport=4000 listenaddress=0.0.0.0 connectport=4000 connectaddress=192.168.127.2
podman run -d ^
  --name ollama-webui ^
  --pull always ^
  --restart unless-stopped ^
  --network %NETWORK_NAME% ^
  -p 0.0.0.0:%WEBUI_PORT_HOST%:%WEBUI_PORT_INTERNAL% ^
  -v %OLLAMA_WEBUI_VOLUME%:/app/backend/data ^
  -e OLLAMA_BASE_URLS=http://ollama:%OLLAMA_PORT_INTERNAL% ^
  -e ENV=dev ^
  -e WEBUI_AUTH=False ^
  -e WEBUI_NAME="Melih Ozaydin AI" ^
  -e WEBUI_URL=http://0.0.0.0:%WEBUI_PORT_INTERNAL% ^
  -e WEBUI_SECRET_KEY=t0p-s3cr3t ^
  -e ENABLE_RAG_WEB_SEARCH=True ^
  -e RAG_WEB_SEARCH_ENGINE="searxng" ^
  -e RAG_WEB_SEARCH_RESULT_COUNT=5 ^
  -e RAG_WEB_SEARCH_CONCURRENT_REQUESTS=5 ^
  -e SEARXNG_QUERY_URL="http://searxng:%SEARXNG_PORT_INTERNAL%/search?q=<query>" ^
  ghcr.io/open-webui/open-webui:main


:: DEBUG
EXIT

echo ------------
echo Run the Ollama service
echo ------------

REM Set a timeout for the container's runtime (12 hours in this case)
::--runtime io.container.scripts.timeout=43200 ollama/ollama:latest

REM Run the Ollama service
podman run -d ^
  --name ollama ^
  --pull always ^
  --restart unless-stopped ^
  --device nvidia.com/gpu=all ^
  --network %NETWORK_NAME% ^
  -p %OLLAMA_PORT_HOST%:%OLLAMA_PORT_INTERNAL% ^
  -v %OLLAMA_VOLUME%:/root/.ollama ^
  -e OLLAMA_KEEP_ALIVE=24h ^
  ollama/ollama:latest

echo ------------
echo Run searxng Web Search
echo ------------

::For Web Search
podman run -d ^
  --name searxng ^
  --pull always ^
  --restart always ^
  --network %NETWORK_NAME% ^
  -p %SEARXNG_PORT_HOST%:%SEARXNG_PORT_INTERNAL% ^
  -v %SEARXNG_VOLUME%:/etc/searxng ^
  searxng/searxng:latest
:: -e "INSTANCE_NAME=searxng-instance" ^
::  -e "BASE_URL=http://localhost:$PORT/" ^
ENDLOCAL