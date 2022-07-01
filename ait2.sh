#!/bin/bash

echo "=================================================="
echo -e "\033[0;35m"
echo " ::::    :::  ::     ::  :::::::::   ::::::::   ";
echo " :+:+:   :+: :+:    :+:     :+:     :+:    :+:  ";
echo " :+:+:+  +:+ +:+    +:+     +:+     +:+         ";
echo " +#+ +:+ +#+ +#+    +:+     +:+     +#++:++#++  ";
echo " +#+  +#+#+# +#+    +#+     +#+             +#+ ";
echo " #+#   #+#+# #+#    #+#     #+#     #+#     #+# ";
echo " ###    ####  ########    ######    ########    ";
echo -e "\e[0m"
echo "=================================================="

sleep 2

# set vars
if [ ! $NODENAME ]; then
	read -p "Введите имя ноды: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
echo "export WORKSPACE=testnet" >> $HOME/.bash_profile
echo "export PUBLIC_IP=$(curl -s ifconfig.me)" >> $HOME/.bash_profile
source $HOME/.bash_profile

echo -e "\e[1m\e[32m1. Updating dependencies... \e[0m" && sleep 1
sudo apt update && sudo apt upgrade -y

echo -e "\e[1m\e[32m2. Installing required dependencies... \e[0m" && sleep 1
sudo apt-get install jq unzip -y
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_amd64 && chmod +x /usr/local/bin/yq

echo -e "\e[1m\e[32m3. Checking if Docker is installed... \e[0m" && sleep 1
if ! command -v docker &> /dev/null
then
    echo -e "\e[1m\e[32m3.1 Installing Docker... \e[0m" && sleep 1
    sudo apt-get install ca-certificates curl gnupg lsb-release -y
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y
fi

echo -e "\e[1m\e[32m4. Checking if Docker Compose is installed ... \e[0m" && sleep 1
docker compose version
if [ $? -ne 0 ]
then
    echo -e "\e[1m\e[32m4.1 Installing Docker Compose v2.6.1 ... \e[0m" && sleep 1
	mkdir -p ~/.docker/cli-plugins/
	curl -SL https://github.com/docker/compose/releases/download/v2.6.1/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
	chmod +x ~/.docker/cli-plugins/docker-compose
	sudo chown $USER /var/run/docker.sock
fi

# download aptos-cli
wget -qO aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v0.1.3/aptos-cli-0.1.2-Ubuntu-x86_64.zip
unzip -o aptos-cli.zip -d /usr/local/bin
chmod +x /usr/local/bin/aptos
rm aptos-cli.zip

echo -e "\e[1m\e[32m5. Installing Validator Node ... \e[0m" && sleep 1
mkdir ~/$WORKSPACE && cd ~/$WORKSPACE

# download configs
wget -qO docker-compose.yaml https://raw.githubusercontent.com/kj89/testnet_manuals/main/aptos/testnet/docker-compose.yaml
wget -qO fullnode.yaml https://raw.githubusercontent.com/kj89/testnet_manuals/main/aptos/testnet/fullnode.yaml
wget -qO validator.yaml https://raw.githubusercontent.com/kj89/testnet_manuals/main/aptos/testnet/validator.yaml

# generate keys
aptos genesis generate-keys --output-dir ~/$WORKSPACE

# configure validator
aptos genesis set-validator-configuration \
  --keys-dir ~/$WORKSPACE --local-repository-dir ~/$WORKSPACE \
  --username $NODENAME \
  --validator-host $PUBLIC_IP:6180 \
  --full-node-host $PUBLIC_IP:6182
  
# generate root key
mkdir keys
aptos key generate --assume-yes --output-file ~/$WORKSPACE/keys/root
ROOT_KEY="0x"$(cat ~/$WORKSPACE/keys/root.pub)

# add layout file
tee layout.yaml > /dev/null <<EOF
---
root_key: "$ROOT_KEY"
users:
  - $NODENAME
chain_id: 23
EOF

# download aptos framework
wget -qO framework.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.2.0/framework.zip
unzip -o framework.zip
rm framework.zip

# compile genesis blob and waypoint
aptos genesis generate-genesis --local-repository-dir ~/$WORKSPACE --output-dir ~/$WORKSPACE

# run docker compose
docker compose up -d

echo "=================================================="
echo -e "\e[1m\e[32mAptos Validator Node Started \e[0m"
echo -e "Please backup key files \e[1m\e[32m$NODENAME.yaml, validator-identity.yaml, validator-full-node-identity.yaml \e[0mlocated in: \e[1m\e[32m~/$WORKSPACE\e[0m"
echo "=================================================="

echo -e "\e[1m\e[32mVerify initial synchronization: \e[0m" 
echo -e "\e[1m\e[39m    curl 127.0.0.1:9101/metrics 2> /dev/null | grep aptos_state_sync_version | grep type \n \e[0m" 

echo -e "\e[1m\e[32mTo view fullnode logs: \e[0m" 
echo -e "\e[1m\e[39m    docker logs -f testnet-fullnode-1 --tail 50 \n \e[0m" 

echo -e "\e[1m\e[32mTo view validator node logs: \e[0m" 
echo -e "\e[1m\e[39m    docker logs -f testnet-validator-1 --tail 50 \n \e[0m" 

echo -e "\e[1m\e[32mTo restart: \e[0m" 
echo -e "\e[1m\e[39m    docker compose restart \n \e[0m" 

echo -e "\e[1m\e[32mTo view keys: \e[0m" 
echo -e "\e[1m\e[39m    cat ~/$WORKSPACE/$NODENAME.yaml \n \e[0m" 
