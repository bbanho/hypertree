#!/bin/bash
# 0_main_entrypoint.sh: Ponto de entrada do agente.
# Captura o conteúdo do clipboard e passa para o orquestrador.

# Garante que estamos no diretório certo para que os caminhos funcionem
cd "$(dirname "$0")"

# Verifica dependências
for cmd in wl-paste wl-copy notify-send; do
  if ! command -v "$cmd" &> /dev/null; then
    notify-send -u critical "Erro de Dependência" "Comando não encontrado: '$cmd'."
    exit 1
  fi
done

# Pega o conteúdo do clipboard
CLIP_CONTENT=$(wl-paste --no-newline)

if [ -z "$CLIP_CONTENT" ]; then
    notify-send -u normal "Agente" "Clipboard vazio."
    exit 0
fi

notify-send "Agente" "Processando: $CLIP_CONTENT"

# Chama o orquestrador com o conteúdo do clipboard e captura a resposta
FINAL_RESPONSE=$(./1_orchestrator.sh "$CLIP_CONTENT")

# Copia a resposta final para o clipboard e notifica o usuário
echo "$FINAL_RESPONSE" | wl-copy
notify-send "Agente Concluído" "Resposta copiada para o clipboard."

# Opcional: exibir a resposta no terminal também
echo "--- Resposta Final ---"
echo "$FINAL_RESPONSE"
echo "---------------------"
