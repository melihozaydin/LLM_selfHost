@echo off
SETLOCAL

:: Clean setup
::podman system prune --all

echo --------------
echo CONFIGURATIONS
echo --------------

REM Set the path to the volumes
SET CONF_ROOT=./service-configs

SET SEARXNG_VOLUME=%CONF_ROOT%/searxng
SET SEARXNG_PORT_HOST=8085
SET SEARXNG_PORT_INTERNAL=8080

SET OLLAMA_VOLUME=%CONF_ROOT%/ollama
SET OLLAMA_PORT_INTERNAL=11434
SET OLLAMA_PORT_HOST=7869

SET OLLAMA_WEBUI_VOLUME=%CONF_ROOT%/ollama-webui
SET WEBUI_PORT_HOST=8087
SET WEBUI_PORT_INTERNAL=8080

SET N8N_VOLUME=%CONF_ROOT%/n8n

REM Debug INFO
echo CONF_ROOT: %CONF_ROOT%
echo ***
echo OLLAMA_VOLUME: %OLLAMA_VOLUME%
echo ***
echo OLLAMA_WEBUI_VOLUME: %OLLAMA_WEBUI_VOLUME%
echo WEBUI_PORT_INTERNAL: %WEBUI_PORT_INTERNAL%
echo WEBUI_PORT_HOST: %WEBUI_PORT_HOST%
echo ***
echo SEARXNG_VOLUME: %SEARXNG_VOLUME%
echo SEARXNG_PORT_INTERNAL: %SEARXNG_PORT_INTERNAL%
echo SEARXNG_PORT_HOST: %SEARXNG_PORT_HOST%
echo ***
echo OLLAMA_PORT_INTERNAL: %OLLAMA_PORT_INTERNAL%
echo OLLAMA_PORT_HOST: %OLLAMA_PORT_HOST%
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

REM Run the Ollama WebUI service
podman run -d ^
  --name ollama-webui ^
  --pull always ^
  --restart unless-stopped ^
  --network %NETWORK_NAME% ^
  -p %WEBUI_PORT_HOST%:%WEBUI_PORT_INTERNAL% ^
  -v %OLLAMA_WEBUI_VOLUME%:/app/backend/data ^
  -e OLLAMA_BASE_URLS=http://ollama:%OLLAMA_PORT_INTERNAL% ^
  -e ENV=dev ^
  -e WEBUI_AUTH=False ^
  -e WEBUI_NAME="Melih Ozaydin AI" ^
  -e WEBUI_URL=http://localhost:%WEBUI_PORT_INTERNAL% ^
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