# Todo Application

A simple Todo application built with Elixir and Phoenix Framework. This application allows users to manage their tasks with features like authentication, task creation, due dates, and task completion tracking.

## Features

- User authentication (registration, login, password reset)
- Create and manage todo items
- Add titles and detailed descriptions to tasks
- Set optional due dates for tasks
- Mark tasks as completed
- Track when tasks were created and completed

## Technology Stack

- **Backend**: Elixir & Phoenix Framework
- **Database**: PostgreSQL
- **Frontend**: Phoenix Templates with TailwindCSS

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- PostgreSQL 13 or later
- Docker (optional, for running PostgreSQL)

### Running with Docker

1. Start the PostgreSQL container:

```bash
docker-compose up -d
```

2. Setup the application:

```bash
# Get dependencies
mix deps.get

# Create and migrate the database
mix ecto.setup

# Start the Phoenix server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.

### Running Tests

```bash
mix test
```

## License

This project is licensed under the MIT License - see the LICENSE file for details.