#!/bin/zsh

function main() {
  make_symbolics_links
  add_init
}

function make_symbolics_links() {
  local ABSOLUTE_PATH=`pwd`

  ln -s $ABSOLUTE_PATH/zsh_init ~/.zsh_init
  ln -s $ABSOLUTE_PATH/zshenv ~/.zshenv
  ln -s $ABSOLUTE_PATH/zsh_functions ~/.zsh_functions
  ln -s $ABSOLUTE_PATH/zsh_code ~/.zsh_code
  ln -s $ABSOLUTE_PATH/zsh_alias ~/.zsh_alias
}

function add_init() {
  if [ -f ~/.zshrc ]
  then
    echo "source ~/.zsh_init" > ~/.zshrc
  else
    echo -e "\e[31m The zshrf file don't exist \e[0m"
  fi

}

main
