# Architecture

Hypertree is designed with a client-server architecture to decouple the local desktop interaction from the core agent logic.

## Components

### 1. Server (`server/`)

- **Purpose:** The core brain of the agent. It is a system-agnostic FastAPI application designed to run in a Docker container.
- **Responsibilities:**
  - Exposing a REST API (e.g., `/v1/execute`).
  - Receiving prompts from any client.
  - Interacting with a Language Model (LLM) to decide the next action.
  - Parsing LLM responses to differentiate between text answers and tool calls.
  - Dispatching jobs to tools. These tools can be internal Python functions or, in the future, API calls to other containerized services (MCPs).

### 2. Client (`client/`)

- **Purpose:** The local interaction layer that runs on the user's desktop.
- **Responsibilities:**
  - Capturing user context (e.g., clipboard content via `wl-paste`, active window, keyboard shortcuts).
  - Sending the captured context as a prompt to the Server API.
  - Receiving the final result from the server.
  - Displaying the result to the user (e.g., copying to clipboard via `wl-copy`, sending desktop notifications).

## Workflow Example

1. User copies text and presses a hotkey (`mod+c`).
2. A script in `client/` is triggered.
3. The client script sends the clipboard content to the `server` API endpoint.
4. The `server` receives the request, queries the LLM, and executes a tool if required.
5. The `server` returns the final result to the client.
6. The client script receives the result and copies it to the user's clipboard.
