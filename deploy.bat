@echo off
SETLOCAL

:: Clean setup
::podman system prune --all

echo ------------
echo Set the path to the volumes
echo ------------

REM Set the path to the volumes
SET CONF_ROOT=./service-configs
echo %CONF_ROOT%
SET OLLAMA_VOLUME=%CONF_ROOT%/ollama
echo %OLLAMA_VOLUME%
SET OLLAMA_WEBUI_VOLUME=%CONF_ROOT%/ollama-webui
echo %OLLAMA_WEBUI_VOLUME%
SET SEARXNG_VOLUME=%CONF_ROOT%/searxng
echo %SEARXNG_VOLUME%
SET N8N_VOLUME=%CONF_ROOT%/n8n
echo %N8N_VOLUME%


echo ------------
echo Create container network
echo ------------

SET NETWORK_NAME=ollama-docker
echo NETWORK_NAME: %NETWORK_NAME%

podman network create %NETWORK_NAME%

REM Set a timeout for the container's runtime (12 hours in this case)
::--runtime io.container.scripts.timeout=43200 ollama/ollama:latest
echo ------------
echo Run the Ollama WebUI service
echo ------------

REM Run the Ollama WebUI service
podman run -d ^
  --name ollama-webui ^
  --pull always ^
  -v %OLLAMA_WEBUI_VOLUME%:/app/backend/data ^
  --network %NETWORK_NAME% ^
  --add-host host.docker.internal:host-gateway ^
  -p 8080:8082 ^
  -e OLLAMA_BASE_URLS=http://host.docker.internal:7869 ^
  -e ENV=dev ^
  -e WEBUI_AUTH=False ^
  -e WEBUI_NAME="Melih Ozaydin AI" ^
  -e WEBUI_URL=http://localhost:8080 ^
  -e WEBUI_SECRET_KEY=t0p-s3cr3t ^
  -e ENABLE_RAG_WEB_SEARCH=True ^
  -e RAG_WEB_SEARCH_ENGINE="searxng" ^
  -e RAG_WEB_SEARCH_RESULT_COUNT=5 ^
  -e RAG_WEB_SEARCH_CONCURRENT_REQUESTS=5 ^
  -e SEARXNG_QUERY_URL="http://searxng:8080/search?q=<query>" ^
  --restart unless-stopped ^
  ghcr.io/open-webui/open-webui:main


:: DEBUG
::EXIT

echo ------------
echo Run the Ollama service
echo ------------
REM Run the Ollama service
podman run -d ^
  --name ollama ^
  --pull always ^
  --tty ^
  --restart unless-stopped ^
  --device nvidia.com/gpu=all ^
  -v %OLLAMA_VOLUME%:/root/.ollama ^
  -p 7869:11434 ^
  -e OLLAMA_KEEP_ALIVE=24h ^
  --network %NETWORK_NAME% ^
  ollama/ollama:latest

echo ------------
echo Run searxng Web Search
echo ------------

::For Web Search
podman run -d ^
  --name searxng ^
  --network %NETWORK_NAME% ^
  -p 8085:8080 ^
  -v %SEARXNG_VOLUME%:/etc/searxng ^
  --restart always ^
  searxng/searxng:latest
:: -e "INSTANCE_NAME=searxng-instance" ^
::  -e "BASE_URL=http://localhost:$PORT/" ^
ENDLOCAL