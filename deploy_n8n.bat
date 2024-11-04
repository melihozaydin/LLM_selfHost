@echo off

:: https://docs.n8n.io/hosting/installation/docker/#prerequisites

SETLOCAL
SET N8N_VOLUME=./service-configs/n8n

podman run -d ^
  --name n8n ^
  --network ollama-docker ^
  -p 5678:5678 ^
  --restart always ^
  -v %N8N_VOLUME%:/home/node/.n8n ^
  docker.n8n.io/n8nio/n8n

ENDLOCAL