# Hypertree

Hypertree is a context-aware AI assistant deeply integrated with the Hyprland window manager. It is built with a client-server architecture to create a powerful, extensible, and system-agnostic agent.

## Core Concepts

- **Client-Server Architecture:** The project is split into two main components:
  - **Client:** A lightweight component on the local desktop responsible for capturing context (hotkeys, clipboard) and interacting with the user's UI (notifications, etc.).
  - **Server:** A powerful, container-ready FastAPI application that houses the core logic, communicates with LLMs, and orchestrates tool use. This server can be extended with other containerized services (MCPs).

- **Contextual Intelligence:** Uses context from the user's environment (active window, clipboard content, screenshots) to provide relevant assistance.

- **Extensible Tool Use:** The server is designed to dispatch tasks to a variety of tools, from executing shell commands to calling other specialized AI agents.

## Project Structure

The repository is organized as follows:

- `client/`: Contains all scripts and components that run on the local machine.
- `server/`: Contains the FastAPI application, core logic, and tool definitions.
- `docs/`: Project documentation, including architecture and design decisions.

## Getting Started

### Prerequisites

- A running LLM service with an OpenAI-compatible API endpoint.
- Python 3.10+
- `uvicorn`, `fastapi`

### 1. Run the Server

Navigate to the server directory, install dependencies, and start the API:

```bash
cd server/
pip install -r requirements.txt
uvicorn src.daemon:app --reload
```

The API will be available at `http://127.0.0.1:8000`.

### 2. Use the Client

The primary entrypoint for the client is the `client/core/0_main_entrypoint.sh` script. By default, it is configured to be triggered by a hotkey (`mod+c` in the provided Hyprland configuration).

1. Copy a piece of text to your clipboard (e.g., `list all files here`).
2. Press the configured hotkey.
3. The client will send the prompt to the server, and the result will be copied back to your clipboard.

## Documentation

For a deeper understanding of the project's vision and architecture, please refer to the documents below:

- **[Architecture](docs/architecture.md):** A detailed overview of the client-server architecture.
- **[Vision (Piloto)](docs/piloto.md):** The original high-level vision and long-term roadmap for the project.
- **[Usage](docs/usage.md):** Instructions on how to use and interact with the assistant.