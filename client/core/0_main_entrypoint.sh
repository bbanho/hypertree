#!/bin/bash
# 0_main_entrypoint.sh: Ponto de entrada do cliente local Hypertree.
# Captura o conteúdo do clipboard e envia para o LM Studio.

# --- Configuração ---
LOCAL_API_URL="http://192.168.200.112:1234/v1/chat/completions" # Endpoint do LM Studio
LOCAL_TEXT_MODEL="google/gemma-3-4b" # Modelo que você usa no LM Studio

# Verifica dependências
for cmd in wl-paste wl-copy notify-send curl jq; do
  if ! command -v "$cmd" &> /dev/null; then
    notify-send -u critical "Hypertree Client Erro" "Dependência não encontrada: '$cmd'."
    exit 1
  fi
done

# Pega o conteúdo do clipboard (priorizando seleção primária)
CLIP_CONTENT=$(wl-paste --primary --no-newline)
if [ -z "$CLIP_CONTENT" ]; then
    CLIP_CONTENT=$(wl-paste --no-newline)
fi

if [ -z "$CLIP_CONTENT" ]; then
    notify-send -u normal "Hypertree" "Clipboard vazio."
    exit 0
fi

notify-send "Hypertree" "Enviando para o LM Studio: $CLIP_CONTENT"

# Prepare o prompt flexível para a IA
PROMPT="Você é um assistente especialista. O texto a seguir foi extraído do clipboard. Interprete sua intenção e responda de forma apropriada.

*   Se for uma pergunta, responda-a de forma completa.
*   Se for um trecho de código, analise-o e explique sua funcionalidade.
*   Se for uma instrução direta para você (a IA), siga-a.
*   Se for um termo ou conceito, forneça uma definição clara e concisa.
*   Se a intenção não for clara, faça uma suposição inteligente e prossiga.

Clipboard content:
'''
$CLIP_CONTENT
'''
"

# Cria o payload JSON para a requisição para o LM Studio
TEMP_JSON_PAYLOAD=$(mktemp)
jq -n \
  --arg model "$LOCAL_TEXT_MODEL" \
  --arg user_content "$PROMPT" \
  '{"model": $model, "messages": [{"role": "user", "content": $user_content}], "temperature": 0.7, "max_tokens": 2048, "stream": false}' > "$TEMP_JSON_PAYLOAD"

# Chama a API do LM Studio
API_RESPONSE=$(curl -s -X POST "$LOCAL_API_URL" \
  -H "Content-Type: application/json" \
  -d "@$TEMP_JSON_PAYLOAD")

rm -f "$TEMP_JSON_PAYLOAD"

# Extrai o texto da resposta da API do LM Studio
FINAL_RESPONSE=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content')

# Copia a resposta final para o clipboard e notifica o usuário
echo "$FINAL_RESPONSE" | wl-copy
notify-send "Hypertree Concluído" "Resposta do LM Studio copiada para o clipboard."

# Opcional: exibir a resposta no terminal também
echo "--- Resposta do LM Studio ---"
echo "$FINAL_RESPONSE"
echo "---------------------"