FROM elixir:1.14

# Install system packages
RUN apt-get update && apt-get install -y \
  curl \
  git \
  inotify-tools \
  build-essential \
  npm \
  nodejs \
  postgresql-client \
  && apt-get clean

# Install hex and rebar
RUN mix local.hex --force && mix local.rebar --force

WORKDIR /workspace
