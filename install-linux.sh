#!/bin/bash
set -e

# Update system

sudo pacman -Syu

# Install packages

## Essentials
sudo pacman -S --needed --noconfirm git vim base-devel stow github-cli zoxide ttf-jetbrains-mono-nerd
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
rm -rf yay

## Install lazyvim and its dependencies
sudo pacman -S --needed --noconfirm neovim wl-clipboard fzf lazygit fd ast-grep ripgrep luarocks nodejs npm lynx
sudo npm install -g neovim
mv ~/.config/nvim{,.bak}
mv ~/.local/share/nvim{,.bak}
mv ~/.local/state/nvim{,.bak}
mv ~/.cache/nvim{,.bak}

## Install yazi file explorer and starship prompt
sudo pacman -S --needed --noconfirm yazi starship

## Install rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
rustup component add rust-analyzer

# Setting up config files

stow -d "$(dirname "${BASH_SOURCE[0]}")" -t "$HOME" .
