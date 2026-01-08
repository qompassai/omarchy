# lua.sh
# Qompass AI - [Add description here]
# Copyright (C) 2025 Qompass AI, All rights reserved
# ----------------------------------------
git clone https://luajit.org/git/luajit.git ~/src/luajit
cd ~/src/luajit
make

# Install rootlessly to ~/.local
make install PREFIX=$HOME/.local
