import subprocess
from fastapi import FastAPI
from pydantic import BaseModel

# Define the data model for the request body
class CommandRequest(BaseModel):
    prompt: str

# Create the FastAPI app
app = FastAPI(
    title="Hypertree Core API",
    description="API for the Hypertree context-aware agent.",
    version="0.1.0",
)

@app.post("/v1/execute", response_model=str)
def execute_command(request: CommandRequest):
    """
    Receives a prompt, executes it through the core agent orchestrator,
    and returns the final result.
    """
    script_path = "./core/1_orchestrator.sh"
    
    # We call the shell script and pass the prompt as an argument
    # The script's output (stdout) will be the result
    try:
        result = subprocess.run(
            [script_path, request.prompt],
            capture_output=True,
            text=True,
            check=True, # Raises CalledProcessError if the script returns a non-zero exit code
            cwd=".." # Run from the root of the hypertree project
        )
        return result.stdout
    except subprocess.CalledProcessError as e:
        # If the script fails, return the error message
        return f"Error executing orchestrator: {e.stderr}"
    except FileNotFoundError:
        return f"Error: Orchestrator script not found at {script_path}"

@app.get("/")
def read_root():
    return {"message": "Hypertree API is running."}