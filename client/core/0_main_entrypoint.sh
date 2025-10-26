#!/bin/bash
# 0_main_entrypoint.sh: Ponto de entrada do cliente local Hypertree.
# Captura o conteúdo do clipboard e envia para a API do servidor Hypertree.

# --- Configuração ---
API_URL="http://127.0.0.1:8000/v1/execute"

# Verifica dependências
for cmd in wl-paste wl-copy notify-send curl jq; do
  if ! command -v "$cmd" &> /dev/null; then
    notify-send -u critical "Hypertree Client Erro" "Dependência não encontrada: '$cmd'."
    exit 1
  fi
done

# Pega o conteúdo do clipboard
CLIP_CONTENT=$(wl-paste --primary --no-newline)

# Se a seleção primária estiver vazia, tenta o clipboard principal
if [ -z "$CLIP_CONTENT" ]; then
    CLIP_CONTENT=$(wl-paste --no-newline)
fi

if [ -z "$CLIP_CONTENT" ]; then
    notify-send -u normal "Hypertree" "Clipboard vazio."
    exit 0
fi

notify-send "Hypertree" "Enviando para a API: $CLIP_CONTENT"

# Cria o payload JSON para a requisição
JSON_PAYLOAD=$(jq -n --arg prompt "$CLIP_CONTENT" '{"prompt": $prompt}')

# Chama a API do servidor com o conteúdo do clipboard
API_RESPONSE=$(curl -s -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -d "$JSON_PAYLOAD")

# Extrai o resultado da resposta da API
FINAL_RESPONSE=$(echo "$API_RESPONSE" | jq -r '.result')

# Copia a resposta final para o clipboard e notifica o usuário
echo "$FINAL_RESPONSE" | wl-copy
notify-send "Hypertree Concluído" "Resposta da API copiada para o clipboard."

# Opcional: exibir a resposta no terminal também
echo "--- Resposta da API ---"
echo "$FINAL_RESPONSE"
echo "---------------------"
