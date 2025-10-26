import subprocess
import json
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel

# --- Data Models ---
class CommandRequest(BaseModel):
    prompt: str

class ToolCall(BaseModel):
    tool_name: str
    parameters: dict

# --- Tool Implementations ---
# In the future, these could be API calls to other Docker containers (MCPs)
def run_shell_command(parameters: dict):
    command = parameters.get("command")
    if not command:
        raise HTTPException(status_code=400, detail="Parameter 'command' is required for run_shell_command")
    
    try:
        # Using a shell for simplicity, but for production, avoid shell=True
        # or carefully sanitize the command.
        result = subprocess.run(
            command, 
            shell=True, 
            capture_output=True, 
            text=True, 
            check=True
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        return f"Command failed with exit code {e.returncode}:\n{e.stderr}"

AVAILABLE_TOOLS = {
    "run_shell_command": run_shell_command,
}

# --- LLM Interaction (Placeholder) ---
def get_llm_response(prompt: str) -> str:
    # This is a placeholder for the actual LLM call.
    # In a real scenario, this would make an HTTP request to the LLM service.
    # For now, we simulate the LLM's JSON output for a specific command.
    if "list files" in prompt.lower():
        return json.dumps({
            "tool_name": "run_shell_command",
            "parameters": {"command": "ls -la"}
        })
    return f"This is a simple text response to the prompt: '{prompt}'"

# --- FastAPI App ---
app = FastAPI(
    title="Hypertree Core API",
    description="API for the Hypertree context-aware agent.",
    version="0.2.0",
)

@app.post("/v1/execute")
def execute_command(request: CommandRequest):
    """
    Receives a prompt, gets a response from the LLM, and either returns 
    the text response or executes a tool call.
    """
    # 1. Get response from LLM
    llm_output = get_llm_response(request.prompt)

    # 2. Try to parse as a tool call
    try:
        # A simple way to check if it's a JSON string
        if llm_output.strip().startswith("{"):
            tool_data = json.loads(llm_output)
            call = ToolCall(**tool_data)
            
            # 3. Execute the tool
            if call.tool_name in AVAILABLE_TOOLS:
                tool_function = AVAILABLE_TOOLS[call.tool_name]
                result = tool_function(call.parameters)
                return {"result": result, "type": "tool_output"}
            else:
                raise HTTPException(status_code=400, detail=f"Tool '{call.tool_name}' not found.")
        else:
            # It's a plain text response
            return {"result": llm_output, "type": "text"}
    except (json.JSONDecodeError, Exception) as e:
        # If parsing fails or it's not a valid tool call, treat as plain text
        return {"result": llm_output, "type": "text"}