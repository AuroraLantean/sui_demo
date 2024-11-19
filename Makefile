-include .env

.PHONY: all clean build remove prove test 
#all targets in your Makefile which do not produce an output file with the same name as the target name should be PHONY.

all: clean remove install update build

clean :; rm -r build
#fmt :; movefmt --dir-path /mnt/sda3/asui/demo/sources //Mysten lab does not have an official Move formatter
build :; sui move build
test :; sui move test
test_s :; sui move test -s
test_counter :; sui move test counter
test_sword :; sui move test sword
test_nft :; sui move test nft
test_coin :; sui move test coin
test_market :; sui move test market

new_addr :; sui client new-address ed25519
activate_addr :; sui client active-address
switch :; sui client switch --address YOUR_ADDRESS
balance :; sui client balance
faucet :; sui client faucet
activate_testnet :; sui client switch --env testnet
activate_devnet :; sui client switch --env devnet

publish_coin1 :; sui client publish --gas-budget 50000000 ./sources/coin.move
publish :; sui client publish --gas-budget 50000000 
read_object :; sui client object object_id
#./sources/calculator.move

suiscan :; echo "https://suivision.xyz/"
PACKAGE_ID=0xf2960e4b47134315c96a609c0c9edd34fd716e025e0e8d4f7bc46394f17125d3
wallet2=0x015251dbd9732e36fe47fb8e58b4ac1e2ba9c3cce2679d26f5573f334a410756
mint_coin :; sui client call --package $(PACKAGE_ID) --module dragoncoin --function mint --args 0x9127f84335a492a8b6784c1a684724be164caa5e5556b52c9b2b39f0de098921 ${wallet2} 500000000000000 --gas-budget 50000000

transfer_coin :; sui client transfer --to recipient --object-id Coin_Object_Id --gas-budget 50000000
#transfer_coin :; sui client call --package $(PACKAGE_ID) --module dragoncoin --function transfer --args 0x6b30ea36c885f9ddbece6529dd5a953c6bc248729269b46f457709c6d11d775d ${wallet2} --gas-budget 50000000

#-----------== NFT Walrus
mint_nft_walrus :; sui client call --package $PACKAGE_ID --module simple_nft --function mint_nft --args "NFT Name" "NFT Description" \
"YOUR_WALRUS_BLOB_ID" \
"YOUR_WALRUS_OBJECT_ID" \
--gas-budget 10000000

list_coin_balc :; sui client gas

#0.1 SUI to NFT (100000000 MIST)
deposit_sui_to_nft :; sui client call --package $PACKAGE_ID --module simple_nft --function deposit_sui --args $NFT_ID $COIN_ID 100000000 --gas-budget 10000000

withdraw_sui_from_nft :; sui client call --package $PACKAGE_ID --module simple_nft --function withdraw_sui \
--args $NFT_ID 100000000 \
--gas-budget 10000000

#-----------== NFT
mint_nft :; sui client call --package $(PACKAGE_ID) --module nft --function mint --args "002_CatHungry" "['cat', 'hungry', 'sleepy']" "https://peach-tough-crayfish-991.mypinata.cloud/ipfs/QmNoGLRSVGW1f3y3djeKR1sj249PB3J5zkZoYyCCpTq1bg" --gas-budget 500000000

transfer_nft :; sui client call --package $(PACKAGE_ID) --module nft --function transfer --args 0x60d5a4b75015fc13275b0d6f844e3048f226af612894d0dcf61e0fac26333360 ${wallet2} --gas-budget 500000000

new_market :; sui client call --function new --module gameMarket --package $(PACKAGE_ID) --type-args 0x2::sui::SUI --gas-budget 10000000000
marketId=0x123Abc
new_widget :; sui client call --function mint --module marketWidget --package $(PACKAGE_ID) --gas--budget 10000000000

list_item :; sui client call --function list_item --module gameMarket --package $(PACKAGE_ID) --args $(marketId) $(itemId) 1 --type-args $(PACKAGE_ID)::widget::Widget 0x2::sui::SUI --gas-budget 10000000000

split :; sui client split-coin --coin-id Coin_Object_Id --amounts 1 --gas-budget 10000000000

buy_widget :; sui client call --function buy_and_take --module gameMarket --package $(PACKAGE_ID) --args $(marketId) $(itemId) $(paymentId) --type-args $(PACKAGE_ID)::widget::Widget 0x2::sui::SUI --gas-budget 10000000000

withdraw :; sui client call --function buy_and_take --module gameMarket --package $(PACKAGE_ID) --args $(marketId) --type-args 0x2::sui::SUI --gas-budget 10000000000


addItem :; sui move run --function-id "0x_publisher_address::advanced_list::add_item"

getListCounter :; sui move view --function-id "0x_publisher_address::advanced_list::get_list_counter" --args address:0x_publisher_address

env :; source .env