# Todo Application

A simple Todo application built with Elixir and Phoenix Framework.

## Features

- User authentication (registration, login, password reset)
- Create and manage todo items
- Add titles and detailed descriptions to tasks
- Set optional due dates for tasks
- Mark tasks as completed
- Track when tasks were created and completed
- Real-time updates using Phoenix LiveView and PubSub

## Technology Stack

- **Backend**: Elixir & Phoenix Framework
- **Database**: PostgreSQL
- **Frontend**: Phoenix Templates with TailwindCSS
- **Real-time**: Phoenix LiveView and PubSub

## Local Environment Setup
This project utilized dev containers in VS Code to have a common docker image to work within. To setup your local machine for dev containers you will:
1. Install Docker Desktop
2. Install VS Code
3. Install VS Code plugin Dev Containers (ms-vscode-remote.remote-containers)

## Spinning up Dev Containers
Follow these steps to get up and running with Elixir project in the dev container.

1. Start Docker Desktop
2. Clone repo to your local machine `git clone git@github.com:Axian-Inc/ffthh-april-2025.git`
3. Open repo in VS Code
4. When prompted to Re-Open in Container, click Yes
5. Wait for container spin up and project to spin up.
6. You should have 2 containers running and be in a terminal prompt

## Running the project
Run these commands to download dependencies, and start the app server

```bash
# get dependencies
mix deps.get

# setup the database via the ORM
mix ecto.setup

# compile the project
mix compile

# run the app server
mix phx.server
```

Visit [`localhost:4000`](http://localhost:4000) from your browser.


### Running Tests

```bash
mix test
```

## Project Structure

- `/lib/todo` - Core business logic
  - `/accounts` - User authentication
  - `/tasks` - Todo item management
- `/lib/todo_web` - Web interface
  - `/controllers` - HTTP request handlers
  - `/live` - LiveView components
  - `/templates` - HTML templates

## Optimized Data Flow

The application uses optimized PubSub patterns:
- Delta updates (only changed fields are sent)
- Event-specific broadcasts
- In-memory updates to avoid redundant database queries
