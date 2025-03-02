#!/bin/bash

# Define main variables
REPOSITORY_URL="https://github.com/avryahov/shvirtd-example-python.git"
BRANCH_NAME="task3-feature"
TARGET_DIR="/opt/shvirtd-example-python"
COMPOSE_FILE="compose.yaml"

# Define function to display a message
handle_error() {
    local message="$1"
    echo "$message"
    exit 1
}

# Step 1: Clone the repository and checkout the branch
echo "Cloning the repository..."
if git clone "$REPOSITORY_URL" /tmp/shvirtd-example-python; then
    echo "Repository cloned successfully."
    cd /tmp/shvirtd-example-python || handle_error "Failed to change directory."
    git switch "$BRANCH_NAME" || handle_error "Failed to checkout branch."
else
    handle_error "Failed to clone the repository."
fi

# Step 2: Move the cloned repository to /opt
echo "Moving the repository to $TARGET_DIR..."
sudo mv /tmp/shvirtd-example-python "$TARGET_DIR" || handle_error "Failed to move the repository."

# Step 3: Navigate to the target directory
cd "$TARGET_DIR" || handle_error "Failed to navigate to $TARGET_DIR."

# Step 4: Start Docker Compose with compose.yaml
echo "Starting Docker Compose with $COMPOSE_FILE..."
if docker compose -f "$COMPOSE_FILE" up -d; then
    echo "Docker Compose started successfully."
else
    handle_error "Failed to start Docker Compose."
fi