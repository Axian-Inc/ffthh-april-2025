# CLAUDE.md - AI Assistant Guidelines

## Build/Test Commands
- Build: `mix compile`
- Lint: `mix format`
- Run server: `mix phx.server`
- Test: `mix test`
- Single test: `mix test test/path/to/test_file.exs:line_number`
- DB setup: `mix ecto.setup`
- DB reset: `mix ecto.reset`
- Start PostgreSQL: `docker-compose up -d`

## Code Style Guidelines
- **Formatting**: Use `mix format` with default settings
- **Types**: Use `@type` and `@spec` for public functions
- **Imports**: Group imports by modules (Elixir core, Phoenix, internal)
- **Naming**:
  - `snake_case` for variables, functions, modules and files
  - `CamelCase` for types/behaviours
  - `UPPER_SNAKE_CASE` for constants
- **Error Handling**: Use with/case statements for error handling
- **Functions**: Keep functions small and focused on a single task
- **Contexts**: Group related functionality in context modules
- **Schema**: Define schemas with clear field types and validations

## Repository Structure
- `/lib/todo`: Core business logic
  - `/accounts`: User authentication
  - `/tasks`: Todo items logic
- `/lib/todo_web`: Web interface
  - `/controllers`: Request handlers
  - `/components`: View components
- `/priv/repo`: Database migrations and seeds