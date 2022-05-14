#!/bin/bash

function logo {
  curl -s https://raw.githubusercontent.com/95brsu/tools/main/nuts.sh | bash
}

function line {
  echo "----14.05.2022--------------------------------------------------------------------"
}

function colors {
  GREEN="\e[1m\e[32m"
  RED="\e[1m\e[39m"
  NORMAL="\e[0m"
}


function make_folder {
  export WORKSPACE=testnet
  mkdir ~/$WORKSPACE
  cd ~/$WORKSPACE
  wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
  wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml
  wget https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/fullnode.yaml
  
}
function install_aptos {
  cargo install --git https://github.com/aptos-labs/aptos-core.git aptos --tag aptos-cli-latest
  which aptos
}



colors

line
logo
line
echo -e "${RED}Создаем папку TESTNET и начинаем установку APTOS CLI ${NORMAL}"
line
make_folder
line
install_aptos
line
echo -e "${RED}Скрипт завершил свою работу!!!${NORMAL}"
