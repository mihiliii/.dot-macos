#!/bin/bash
set -e

# Install Homebrew if missing

if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Update system

brew update
brew upgrade

# Install packages

## Essentials
brew install git vim stow gh zoxide
brew install --cask font-jetbrains-mono-nerd-font

## Install lazyvim and its dependencies
brew install neovim fzf lazygit fd ast-grep ripgrep luarocks node lynx
npm install -g neovim
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

## Install yazi file explorer and starship prompt
brew install yazi starship

## Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup component add rust-analyzer

# Setting up config files

stow -d "$(dirname "${BASH_SOURCE[0]}")" -t "$HOME" .
