-include .env

.PHONY: all clean build remove prove test 
#all targets in your Makefile which do not produce an output file with the same name as the target name should be PHONY.

all: clean remove install update build

clean :; rm -r build
format :; movefmt
build :; sui move build
test :; sui move test
test2 :; sui move test counter

check_tokens :; sui client balance
get_tokens :; sui client faucet

activate_testnet :; sui client switch --env testnet
activate_devnet :; sui client switch --env devnet

publish_coin1 :; sui client publish --gas-budget 50000000 ./sources/coin.move

suiscan :; echo "https://suivision.xyz/"

mint :; sui client call --package 0x004d04754adaa8ffadd51a8542bc286b536f4f7954d7336afe09e45157f62c25 --module dragoncoin --function mint --args 0x9127f84335a492a8b6784c1a684724be164caa5e5556b52c9b2b39f0de098921 0x015251dbd9732e36fe47fb8e58b4ac1e2ba9c3cce2679d26f5573f334a410756 500000000000000 --gas-budget 50000000

Nft_object1 :; echo "https://testnet.suivision.xyz/object/0x6b30ea36c885f9ddbece6529dd5a953c6bc248729269b46f457709c6d11d775d"

make_new_addr :; sui client new-address ed25519

transfer :; sui client call --package 0x92207cdfe92222aab906fd3f54d3f8081b98e8f0ea76e481585589a321475d0b --module dragoncoin --function transfer --args 0x6b30ea36c885f9ddbece6529dd5a953c6bc248729269b46f457709c6d11d775d 0x015251dbd9732e36fe47fb8e58b4ac1e2ba9c3cce2679d26f5573f334a410756 --gas-budget 50000000

addItem :; sui move run --function-id "0x_publisher_address::advanced_list::add_item"

getListCounter :; sui move view --function-id "0x_publisher_address::advanced_list::get_list_counter" --args address:0x_publisher_address


prove :; sui move prove --named-addresses publisher=default

#remove :; rm -rf .gitmodules

#ethereum_sepolia :; ${ETHEREUM_SEPOLIA_RPC}

env :; source .env