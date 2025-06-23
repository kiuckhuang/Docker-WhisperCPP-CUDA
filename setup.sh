#!/bin/bash
#
# This script performs the initial setup for the Docker-WhisperCPP-CUDA project.
# It creates the necessary directories and downloads a default model.

# Exit immediately if a command exits with a non-zero status.
set -e

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
set -o allexport
. ${SCRIPT_DIR}/.env
set +o allexport

echo "--- Starting Project Setup ---"

# Check if we are already inside the project directory.
if [[ $(basename "$PWD") != "$PROJECT_DIR" ]]; then
  echo "Creating project directory: $PROJECT_DIR"
  mkdir -p "$PROJECT_DIR"
  cd "$PROJECT_DIR"
fi

echo "Creating subdirectories..."
mkdir -p "$SAMPLES_DIR"
mkdir -p "$MODELS_DIR"

# Navigate to the models directory.
cd "$MODELS_DIR"

# Download the model only if it doesn't already exist.
if [ -f "$MODEL_FILENAME" ]; then
  echo "Model '$MODEL_FILENAME' already exists. Skipping download."
else
  echo "Downloading default model: $MODEL_FILENAME..."
  wget -q --show-progress -O "$MODEL_FILENAME" "$DEFAULT_MODEL_URL"
fi

echo "--- Setup Complete ---"
echo "You can now run 'docker compose build' and 'docker compose up -d'."
