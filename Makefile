-include .env

.PHONY: all clean build remove prove test 
#all targets in your Makefile which do not produce an output file with the same name as the target name should be PHONY.

all: clean remove install update build

clean :; rm -r build
format :; movefmt
build :; sui move build
build2 :; sui move build --named-addresses publisher=default
test :; sui move test
test2 :; sui move test --named-addresses publisher=default

check_tokens :; sui client balance
get_tokens :; sui client faucet

setup_testnet :; sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443

activate_testnet :; sui client switch --env testnet

publish :; sui client publish --gas-budget 50000000 # 20000000

mint :; sui client call --package 0xa85c6cc78f5723759ecb5568f625a9cd2315fedec651017af1508496994e0f29 --module sui_nft --function mint --args "Gold Coin1" "My first NFT on SUI Blockchain" --gas-budget 50000000

Nft_object1 :; echo "https://testnet.suivision.xyz/object/0x6b30ea36c885f9ddbece6529dd5a953c6bc248729269b46f457709c6d11d775d"

make_new_addr :; sui client new-address ed25519

transfer :; sui client call --package 0xa85c6cc78f5723759ecb5568f625a9cd2315fedec651017af1508496994e0f29 --module sui_nft --function transfer --args 0x6b30ea36c885f9ddbece6529dd5a953c6bc248729269b46f457709c6d11d775d 0x015251dbd9732e36fe47fb8e58b4ac1e2ba9c3cce2679d26f5573f334a410756 --gas-budget 50000000

addItem :; sui move run --function-id "0x_publisher_address::advanced_list::add_item"

getListCounter :; sui move view --function-id "0x_publisher_address::advanced_list::get_list_counter" --args address:0x_publisher_address


prove :; sui move prove --named-addresses publisher=default

#remove :; rm -rf .gitmodules

#ethereum_sepolia :; ${ETHEREUM_SEPOLIA_RPC}

env :; source .env