#!/bin/bash
# Ferramenta: run_shell_command.sh
# Executa um comando de shell recebido via JSON.

# O primeiro argumento é uma string JSON com os parâmetros, ex: '{"command":"ls -l"}'
PARAMETERS_JSON=$1

if [ -z "$PARAMETERS_JSON" ]; then
    echo "Erro: Nenhum parâmetro JSON fornecido."
    exit 1
fi

# Extrai o comando do JSON usando jq
COMMAND_TO_RUN=$(echo "$PARAMETERS_JSON" | jq -r '.command')

if [ -z "$COMMAND_TO_RUN" ] || [ "$COMMAND_TO_RUN" == "null" ]; then
    echo "Erro: Parâmetro 'command' não encontrado no JSON."
    exit 1
fi

# Executa o comando e retorna o resultado
echo "Executando comando: $COMMAND_TO_RUN"
echo "--- Início da Saída ---"

# Usamos eval para garantir que comandos com pipes e redirecionamentos funcionem
eval "$COMMAND_TO_RUN"

echo "--- Fim da Saída ---"
