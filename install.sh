#!/bin/bash

# Installation script for bash-tools
VERSION=$(cat VERSION)

set -e

# Check if already installed
if [ -f ~/.bash-tools/VERSION ]; then
  CURRENT_VERSION=$(cat ~/.bash-tools/VERSION)
  if [ "$CURRENT_VERSION" == "$VERSION" ]; then
    echo "bash-tools v$VERSION is already installed"
    exit 0
  else
    echo "Upgrading bash-tools from v$CURRENT_VERSION to v$VERSION"
  fi
fi

# Create required directories
mkdir -p ~/.bash-tools/{bin,tests}

# Install bats-core for testing if not present
if ! command -v bats &> /dev/null; then
  echo "Installing bats-core..."
  git clone https://github.com/bats-core/bats-core.git
  cd bats-core
  ./install.sh /usr/local
  cd ..
  rm -rf bats-core
fi

# Install the tools
echo "Installing bash-tools v$VERSION..."
cp -r * ~/.bash-tools/

# Add to shell rc
if ! grep -q "bash-tools" ~/.bashrc; then
  echo "Adding to shell rc file..."
  echo -e "\n# bash-tools" >> ~/.bashrc
  echo "source ~/.bash-tools/index.sh" >> ~/.bashrc
fi

echo "Installation complete. Version: $VERSION"
echo "Please restart your shell or run:"
echo "source ~/.bashrc"