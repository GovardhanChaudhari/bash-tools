#!/bin/bash

# Installation script for bash-tools

set -e

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
echo "Installing bash-tools..."
cp -r * ~/.bash-tools/

# Add to shell rc
echo "Adding to shell rc file..."
echo -e "\n# bash-tools" >> ~/.bashrc
echo "source ~/.bash-tools/index.sh" >> ~/.bashrc

echo "Installation complete. Please restart your shell or run:"
echo "source ~/.bashrc"