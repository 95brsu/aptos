#!/bin/bash
exists()
{
  command -v "$1" >/dev/null 2>&1
}
if exists curl; then
echo ''
else
  sudo apt update && sudo apt install curl -y < "/dev/null"
fi
bash_profile=$HOME/.bash_profile
if [ -f "$bash_profile" ]; then
    . $HOME/.bash_profile
fi
sleep 1 && curl -s https://api.nodes.guru/logo.sh | bash && sleep 1
if grep -q avx2 /proc/cpuinfo; then
	echo ""
else
	echo -e "\e[31mInstallation is not possible, your server does not support AVX2, change your server and try again.\e[39m"
	exit
fi
if lsb_release  -r | grep -q 22; then
	wget http://nz2.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
	dpkg -i libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
fi
if ss -tulpen | awk '{print $5}' | grep -q ":80$" ; then
	echo -e "\e[31mInstallation is not possible, port 80 already in use.\e[39m"
	exit
fi
if ss -tulpen | awk '{print $5}' | grep -q ":6180$" ; then
	echo -e "\e[31mInstallation is not possible, port 6180 already in use.\e[39m"
	exit
fi
if ss -tulpen | awk '{print $5}' | grep -q ":6181$" ; then
	echo -e "\e[31mInstallation is not possible, port 6181 already in use.\e[39m"
	exit
fi
if ss -tulpen | awk '{print $5}' | grep -q ":9101$" ; then
	echo -e "\e[31mInstallation is not possible, port 9101 already in use.\e[39m"
	exit
fi
if [ ! $APTOS_NODENAME ]; then
read -p "Enter node name: " APTOS_NODENAME
echo 'export APTOS_NODENAME='\"${APTOS_NODENAME}\" >> $HOME/.bash_profile
fi
echo 'source $HOME/.bashrc' >> $HOME/.bash_profile
echo "export WORKSPACE=\"$HOME/.aptos\"" >>$HOME/.bash_profile
. $HOME/.bash_profile
apt update && apt install git sudo unzip wget libssl-dev -y
#install docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
#install docker-compose
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
 
#install aptos
wget -qO aptos-cli.zip https://github.com/aptos-labs/aptos-core/releases/download/aptos-cli-v0.3.4/aptos-cli-0.3.4-Ubuntu-x86_64.zip
unzip -o aptos-cli.zip
chmod +x aptos
mv aptos /usr/local/bin 
 
#create folder,download config    
IPADDR=$(curl ifconfig.me) 
sleep 2   
mkdir -p $HOME/.aptos
cd $HOME/.aptos
wget -O $HOME/.aptos/docker-compose.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/docker-compose.yaml
wget -O $HOME/.aptos/validator.yaml https://raw.githubusercontent.com/aptos-labs/aptos-core/main/docker/compose/aptos-node/validator.yaml

sleep 2   
/usr/local/bin/aptos genesis generate-keys --assume-yes --output-dir $HOME/.aptos/keys

sleep 2   
/usr/local/bin/aptos genesis set-validator-configuration \
    --local-repository-dir $HOME/.aptos \
    --username $APTOS_NODENAME \
    --owner-public-identity-file $HOME/.aptos/keys/public-keys.yaml \
    --validator-host $IPADDR:6180 \
    --stake-amount 100000000000000

#aptos genesis generate-layout-template --output-file $HOME/.aptos/layout.yaml

echo "---
root_key: "D04470F43AB6AEAA4EB616B72128881EEF77346F2075FFE68E14BA7DEBD8095E"
users: [\"$APTOS_NODENAME\"]
chain_id: 43
allow_new_validators: false
epoch_duration_secs: 7200
is_test: true
min_stake: 100000000000000
min_voting_threshold: 100000000000000
max_stake: 100000000000000000
recurring_lockup_duration_secs: 86400
required_proposer_stake: 100000000000000
rewards_apy_percentage: 10
voting_duration_secs: 43200
voting_power_increase_limit: 20" >layout.yaml

wget https://github.com/aptos-labs/aptos-core/releases/download/aptos-framework-v0.3.0/framework.mrb -P $HOME/.aptos
    
sleep 2   
/usr/local/bin/aptos genesis generate-genesis --assume-yes --local-repository-dir $HOME/.aptos --output-dir $HOME/.aptos
sleep 2
docker-compose down -v
sleep 2
# Delete old images
docker rmi -f aptoslabs/validator:testnet 2> /dev/null
sleep 1
docker compose up -d
echo -e "Your Aptos node \e[32minstalled and works\e[39m!"






Additional
Check validator node logs:

docker logs -f --tail 100 aptos-validator-1
Restart node:

cd ~/.aptos && docker-compose restart
Stop node:

cd ~/.aptos && docker-compose stop
Progress can be monitored by querying the metrics port:

curl 127.0.0.1:9101/metrics 2> /dev/null | grep aptos_state_sync_version
Information for filling out the form can be viewed by running the commands:

cat ~/.aptos/keys/public-keys.yaml
Ports used:

TCP ports: 80, 6180, 6181, 6182, 9101
Delete node:

cd ~/.aptos && docker-compose down -v
rm -rf ~/.aptos /opt/aptos
