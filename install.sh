#!/bin/zsh

function main() {
  make_symbolics_links
  add_init
}

function make_symbolics_links() {
  local ABSOLUTE_PATH=`pwd`

  ln -sf $ABSOLUTE_PATH/zsh_init ~/.zsh_init
  ln -sf $ABSOLUTE_PATH/zshenv ~/.zshenv
  ln -sf $ABSOLUTE_PATH/zsh_functions ~/.zsh_functions
  ln -sf $ABSOLUTE_PATH/zsh_code ~/.zsh_code
  ln -sf $ABSOLUTE_PATH/zsh_alias ~/.zsh_alias

  if [ -f $ABSOLUTE_PATH/zshenv.local ]
  then
    ln -sf $ABSOLUTE_PATH/zshenv.local ~/.zshenv.local
  fi
}

function add_init() {
  if [ -f ~/.zshrc ]
  then
    grep -qxF "source ~/.zsh_init" ~/.zshrc || echo "source ~/.zsh_init" >> ~/.zshrc
  else
    echo -e "\e[31m The zshrc file don't exist \e[0m"
  fi

}

main
