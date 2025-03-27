# Todo Application

A simple Todo application built with Elixir and Phoenix Framework. This application allows users to manage their tasks with features like authentication, task creation, due dates, and task completion tracking.

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

## Environment Setup

### macOS

1. Install Homebrew if not already installed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install Elixir and Erlang:

```bash
brew install elixir
```

3. Install Docker Desktop:

```bash
brew install --cask docker
```

4. Start Docker Desktop application from Applications folder

### Windows

1. Install Chocolatey (Windows package manager):
   - Open PowerShell as Administrator and run:

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

2. Install Elixir and Erlang:

```powershell
choco install elixir
```

3. Install Docker Desktop:

```powershell
choco install docker-desktop
```

4. Start Docker Desktop application after installation

### WSL2 (Windows Subsystem for Linux)

For Windows users, WSL2 provides a better development experience:

1. Install WSL2 with Ubuntu:
   - Open PowerShell as Admin and run:

```powershell
wsl --install -d Ubuntu
```

2. Within your WSL2 Ubuntu environment:

```bash
# Update package lists
sudo apt update

# Install Erlang dependencies
sudo apt install build-essential autoconf m4 libncurses5-dev libwxgtk3.0-gtk3-dev libwxgtk-webview3.0-gtk3-dev libgl1-mesa-dev libglu1-mesa-dev libpng-dev libssh-dev unixodbc-dev xsltproc fop libxml2-utils libncurses-dev openjdk-11-jdk

# Install Erlang and Elixir
wget https://packages.erlang-solutions.com/erlang-solutions_2.0_all.deb
sudo dpkg -i erlang-solutions_2.0_all.deb
sudo apt update
sudo apt install erlang elixir

# Install Docker
sudo apt install docker.io
sudo usermod -aG docker $USER
# Log out and back in for group changes to take effect
```

3. You'll need to configure Docker Desktop to use WSL2 backend in Windows.

## Getting Started

### Prerequisites

- Elixir 1.14 or later
- Docker Desktop (for running PostgreSQL container)

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

## License

This project is licensed under the MIT License - see the LICENSE file for details.