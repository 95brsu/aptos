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
  IPADDR=$(curl ifconfig.me) 
  sleep 2 
  cargo install --git https://github.com/aptos-labs/aptos-core.git aptos --tag aptos-cli-latest
  cd $HOME/.cargo/bin
  aptos genesis generate-keys --output-dir ~/$WORKSPACE 
  aptos genesis set-validator-configuration \
    --keys-dir ~/$WORKSPACE --local-repository-dir ~/$WORKSPACE \
    --username $USERNAME \
    --validator-host $IPADDR:6180 \
    --full-node-host $IPADDR:6182

cd ~/$WORKSPACE
cat << EOF > layout.yaml
---
root_key: "0x5243ca72b0766d9e9cbf2debf6153443b01a1e0e6d086c7ea206eaf6f8043956"
users:
  - $USERNAME
chain_id: 23
EOF
  }
  
  function install_aptos_v1 {
  apt install unzip
  cd ~/$WORKSPACE
  wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.1.0/framework.zip
  unzip framework.zip
  aptos genesis generate-genesis --local-repository-dir ~/$WORKSPACE --output-dir ~/$WORKSPACE
  docker-compose up -d
  }
  
function update_docker {
  sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/bin/docker-compose
  sudo chmod +x /usr/bin/docker-compose
}




colors

line
logo
line
echo -e "${RED}обновляем Docker${NORMAL}"
update_docker
line
echo -e "${RED}Создаем папку TESTNET и начинаем установку APTOS CLI ${NORMAL}"
line
make_folder
line
install_aptos
install_aptos_v1
line
echo -e "${RED}Скрипт завершил свою работу!!! << docker logs -f testnet-fullnode-1 --tail 50 >>, << docker logs -f testnet-validator-1 --tail 50 >>  ${NORMAL}"
