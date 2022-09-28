#!/bin/bash

while true
do

# Logo

curl -s https://raw.githubusercontent.com/Agus1224/NODE_TESTNET/main/logo_ALFONOVA | bash

# Menu

PS3='Select an action: '
options=(
"Install Node"
"Create wallet"
"Synchronization via StateSync"
"UPDATE"
"Delete Node"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install Node")
echo "*********************"
echo -e "\e[1m\e[35m		Lets's begin\e[0m"
echo "*********************"
echo -e "\e[1m\e[32m	Enter your Validator_Name:\e[0m"
echo "_|-_|-_|-_|-_|-_|-_|"
read Validator_Name
echo "_|-_|-_|-_|-_|-_|-_|"
echo export Validator_Name=${Validator_Name} >> $HOME/.bash_profile
echo export CHAIN_ID="lambdatest_92001-1" >> $HOME/.bash_profile
source ~/.bash_profile

echo -e "\e[1m\e[32m1. Updating packages and dependencies--> \e[0m" && sleep 1
#UPDATE APT
sudo apt update && sudo apt upgrade -y
sudo apt install curl tar wget clang pkg-config libssl-dev libleveldb-dev jq build-essential bsdmainutils git make ncdu htop screen unzip bc fail2ban htop -y

echo -e "        \e[1m\e[32m2. Installing GO--> \e[0m" && sleep 1
#INSTALL GO
ver="1.18.3" && \
cd $HOME && \
wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz" && \
sudo rm -rf /usr/local/go && \
sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz" && \
rm "go$ver.linux-amd64.tar.gz" && \
echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile && \
source $HOME/.bash_profile && \
go version

echo -e "              \e[1m\e[32m3. Downloading and building binaries--> \e[0m" && sleep 1
#INSTALL
cd $HOME && \
git clone https://github.com/LambdaIM/lambdavm.git && \
cd haqq && \
make build && \
sudo cp $HOME/lambdavm/build/lambdavm /usr/local/bin


lambdavm init $Validator_Name --chain-id $CHAIN_ID

curl -OL https://raw.githubusercontent.com/LambdaIM/testnets/main/lambdatest_92001-1/genesis.json
mv genesis.json ~/.lambdavm/config/


echo -e "                     \e[1m\e[32m4. Node optimization and improvement--> \e[0m" && sleep 1

seeds=""
sed -i.bak -e "s/^seeds =.*/seeds = \"$seeds\"/" $HOME/.lambdavm/config/config.toml
peers="6cf8b733252f6d9590010abe6f1dfbb9620f60f0@18.143.13.243:26656"
sed -i.bak -e "s/^persistent_peers *=.*/persistent_peers = \"$peers\"/" $HOME/.lambdavm/config/config.toml

sed -i.bak -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0stake\"/;" ~/.lambdavm/config/app.toml
sed -i -e "s/^filter_peers *=.*/filter_peers = \"true\"/" $HOME/.lambdavm/config/config.toml
external_address=$(wget -qO- eth0.me) 
sed -i.bak -e "s/^external_address *=.*/external_address = \"$external_address:26656\"/" $HOME/.lambdavm/config/config.toml
sed -i 's/max_num_inbound_peers =.*/max_num_inbound_peers = 100/g' $HOME/.lambdavm/config/config.toml
sed -i 's/max_num_outbound_peers =.*/max_num_outbound_peers = 100/g' $HOME/.lambdavm/config/config.toml

# pruning and indexer
pruning="custom" && \
pruning_keep_recent="100" && \
pruning_keep_every="0" && \
pruning_interval="10" && \
sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.lambdavm/config/app.toml && \
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.lambdavm/config/app.toml && \
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.lambdavm/config/app.toml && \
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.lambdavm/config/app.toml
indexer="null" && \
sed -i -e "s/^indexer *=.*/indexer = \"$indexer\"/" $HOME/.lambdavm/config/config.toml


sudo tee /etc/systemd/system/lambdavm.service > /dev/null <<EOF
[Unit]
Description=lambdavm
After=network-online.target

[Service]
User=$USER
ExecStart=$(which lambdavm) start
Restart=on-failure
RestartSec=3
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF


# start service
sudo systemctl daemon-reload
sudo systemctl enable lambdavm
sudo systemctl restart lambdavm

echo '=============== SETUP FINISHED ==================='
echo -e 'Congratulations:        \e[1m\e[32mSUCCESSFUL NODE INSTALLATION\e[0m'
echo -e 'To check logs:        \e[1m\e[33mjournalctl -u lambdavm -f -o cat\e[0m'
echo -e "To check sync status: \e[1m\e[35mcurl -s localhost:26657/status\e[0m"

break
;;
"Create wallet")
echo "_|-_|-_|-_|-_|-_|-_|"
echo -e "      \e[1m\e[35m Your WalletName:\e[0m'"
echo "_|-_|-_|-_|-_|-_|-_|"
read Wallet
echo export Wallet=${Wallet} >> $HOME/.bash_profile
source ~/.bash_profile
lambdavm keys add $Wallet
echo -e "      \e[1m\e[32m!!!!!!!!!SAVE!!!!!!!!!!!!!!!!SAVE YOUR MNEMONIC PHRASE!!!!!!!!!SAVE!!!!!!!!!!!!!!!!\e[0m"

break
;;
"Synchronization via StateSync")
SNAP_RPC=https://rpc-t.lambda.nodestake.top:443
LATEST_HEIGHT=$(curl -s $SNAP_RPC/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 500)); \
TRUST_HASH=$(curl -s "$SNAP_RPC/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

echo $LATEST_HEIGHT $BLOCK_HEIGHT $TRUST_HASH

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"$SNAP_RPC,$SNAP_RPC\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" $HOME/.lambdavm/config/config.toml
lambdavm tendermint unsafe-reset-all --home $HOME/.lambdavm
systemctl restart lambdavm && journalctl -u lambdavm -f -o cat



break
;;
"UPDATE")
lambdavm version
echo -e "      \e[1m\e[35mSOON\e[0m"

break
;;
"Delete Node")
sudo systemctl stop lambdavm && \
sudo systemctl disable lambdavm && \
rm /etc/systemd/system/lambdavm.service && \
sudo systemctl daemon-reload && \
cd $HOME && \
rm -rf .lambdavm && \
rm -rf lambdavm && \
rm -rf $(which lambdavm)

break
;;
"Exit")
exit
esac
done
done
