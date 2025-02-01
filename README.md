# Log Analysis API

Log Analysis API is an OCaml-based REST API designed to process, analyze, and transform log data. It demonstrates the power of OCaml's functional programming paradigm, type safety, and performance for real-world data processing tasks.

## Features

- **Filtering**: Filter logs by log level (e.g., INFO, WARN, ERROR, DEBUG) or by substrings in the log message.
- **Aggregation**: Compute aggregates such as count, average, sum, max, and min for numeric log fields.
- **Transformation**: Convert logs into JSON or CSV formats.
- **Schema Endpoint**: Expose a JSON schema that describes the expected format for log entries.
- **Health Checks**: Basic endpoints to verify service liveness and readiness.

## Prerequisites

- **OCaml** (version 4.08 or later recommended)
- **Dune** build system
- **Opam** package manager

### Required Libraries

- `dream`
- `lwt`
- `yojson`
- `lwt_ppx` (for PPX syntax, e.g., `let%lwt`)

You can install these using opam:

```sh
opam install dream lwt yojson lwt_ppx
```

## Installation and Running
### Clone the repository:  
```sh
git clone https://github.com/yourusername/log-analysis-api.git
cd log-analysis-api
```
### Build the project:  
```sh
dune build
```

### Run the API server:
```sh
dune exec ./your_executable_name
```

The server will start (by default on port 8080) and you can access the endpoints at http://localhost:8080/.

## API Endpoints
### POST /process
Processes a command on the logs loaded from the `data/` folder. The request payload should contain a command. Since logs are read from the source and kept in memory, you only need to pass the command.

Example Payloads:

#### Filter by Log Level ("ERROR"):  
```json
{
    "type": "Filter",
    "criteria": {
        "level": "ERROR"
    }
}
```

#### Filter by Substring in Message ("failed"):  
```json
{
    "type": "Filter",
    "criteria": {
        "message_contains": "failed"
    }
}
```

#### Aggregate (Count by "user_id"):
```json
{
    "type": "Aggregate",
    "criteria": {
        "operation": "CountBy",
        "field": "user_id"
    }
}
```

#### Transform to CSV:
```json
{
  "type": "Transform",
  "format": "CSV"
}
```

### GET /schema
Returns a JSON schema describing the expected log format, including standard fields like timestamp, level, message, and metadata.

### GET /health
A basic health check endpoint that returns the status of the API.

## Log Files
Place your log files (pretty-printed JSON arrays) in the data/ folder. Sample log files are provided in this folder for testing. Each file should contain a valid JSON array of log objects.