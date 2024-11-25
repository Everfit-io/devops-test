# Use the official Python image from the Docker Hub
FROM python:3.12-slim AS base

# Set the working directory in the container
WORKDIR /app

# Copy the pyproject.toml and poetry.lock files into the container
COPY pyproject.toml poetry.lock ./

# Install Poetry
RUN pip install --no-cache-dir poetry

FROM base AS test

RUN poetry install --no-root

COPY . .

FROM base
# Install the dependencies using Poetry
RUN poetry install --no-root --no-dev

# Copy the rest of the application code into the container
COPY . .

# Expose the port the app runs on
EXPOSE 3000

# TODO: use a dedicated wsgi server
ENTRYPOINT [ "poetry", "run", "python3", "main.py"]
