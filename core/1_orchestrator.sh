#!/bin/bash
# 1_orchestrator.sh: O cérebro do agente.
# Ele recebe o input, consulta a IA e decide se responde diretamente ou usa uma ferramenta.

# --- Configuração ---
LOCAL_API_URL="http://192.168.200.112:1234/v1/chat/completions"
LOCAL_TEXT_MODEL="google/gemma-3-4b"

# O input do usuário é recebido como o primeiro argumento
USER_INPUT="$1"

if [ -z "$USER_INPUT" ]; then
    echo "Erro: Nenhum input fornecido."
    exit 1
fi

# --- Definição do Prompt de Ferramentas ---
# Este é o prompt que ensina a IA a formatar a resposta para usar ferramentas.
TOOLS_PROMPT="Você é um assistente poderoso capaz de usar ferramentas.

Para usar uma ferramenta, responda APENAS com um objeto JSON no formato:
{
  \"tool_name\": \"<nome_da_ferramenta>\".
  \"parameters\": {
    \"<param1>\": \"<valor1>\"
  }
}

Ferramentas disponíveis:
- 'run_shell_command': Executa um comando no terminal. Parâmetros: 'command' (string).
- 'web_search': Realiza uma busca na web. Parâmetros: 'query' (string).

Se a resposta não requer ferramentas, responda em texto puro.

---
Solicitação do Usuário:
$USER_INPUT
---" 

# --- Chamada para a IA ---
TEMP_JSON_PAYLOAD=$(mktemp)
jq -n \
  --arg model "$LOCAL_TEXT_MODEL" \
  --arg user_content "$TOOLS_PROMPT" \
  '{"model": $model, "messages": [{"role": "user", "content": $user_content}], "temperature": 0.2, "max_tokens": 2048, "stream": false}' > "$TEMP_JSON_PAYLOAD"

API_RESPONSE=$(curl -s -X POST "$LOCAL_API_URL" \
  -H "Content-Type: application/json" \
  -d @"$TEMP_JSON_PAYLOAD")

rm -f "$TEMP_JSON_PAYLOAD"
RESPONSE_TEXT=$(echo "$API_RESPONSE" | jq -r '.choices[0].message.content')

# --- Lógica de Decisão ---
# Limpa a resposta da IA, removendo possíveis blocos de código markdown
CLEANED_RESPONSE_TEXT=$(echo "$RESPONSE_TEXT" | sed 's/^```json//; s/```$//')

# Verifica se a resposta limpa é um JSON válido (indicando um comando de ferramenta)
if echo "$CLEANED_RESPONSE_TEXT" | jq -e . >/dev/null 2>&1; then
    # É um JSON, então é uma chamada de ferramenta.
    TOOL_NAME=$(echo "$CLEANED_RESPONSE_TEXT" | jq -r '.tool_name')
    TOOL_SCRIPT_PATH="$(dirname "$0")/tools/${TOOL_NAME}.sh"

    if [ -f "$TOOL_SCRIPT_PATH" ]; then
        # Extrai os parâmetros e passa para o script da ferramenta
        PARAMETERS=$(echo "$CLEANED_RESPONSE_TEXT" | jq -c '.parameters')
        # O script da ferramenta é responsável por processar o JSON de parâmetros
        "$TOOL_SCRIPT_PATH" "$PARAMETERS"
    else
        echo "Erro: Ferramenta '$TOOL_NAME' não encontrada em '$TOOL_SCRIPT_PATH'."
    fi
else
    # Não é JSON, então é uma resposta de texto simples.
    echo "$RESPONSE_TEXT"
fi