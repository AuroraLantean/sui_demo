# Sui Demo

## Installation and Setup
Install Sui: https://docs.sui.io/guides/developer/getting-started/sui-install

setup accounts
```
brew install sui
sui --version
make new_addr
make activate_addr
sui client switch --address YOUR_ADDRESS
make balance
make faucet
make activate_testnet
```

https://docs.sui.io/guides/developer/app-examples/e2e-counter

Shared objects: The guide teaches you how to use shared objects, in this case to create a globally accessible HouseData object.

One-time witnesses: The guide teaches you how to use one-time witnesses to ensure only a single instance of the HouseData object ever exists.

Address-owned objects: The guide teaches you how to use address-owned objects when necessary.

Events: The guide teaches you how to emit events in your contracts, which can be used to track off chain.

Storage rebates: The guide shows you best practices regarding storage fee rebates.

MEV attack protection: The guide introduces you to MEV attacks, how to make your contracts MEV-resistant, and the trade-offs between protection and user experience.

#### Set Network to Testnet
```
sui client new-env --alias testnet --rpc https://fullnode.testnet.sui.io:443
sui client switch --env testnet
sui client envs
```
#### Setup Account
```
sui client new-address ed25519
sui client active-address
```
#### Get Test Tokens
```
sui client balance
sui client faucet
## Get Test Tokens
```
sui client balance
sui client faucet
sui client gas
```


#### Publish Coin
```
sui client publish --gas-budget 50000000
```

Check the transaction digest in Suivision.xyz

Find the PackageID:
0xdb8a2519edba3769b48297f479a16e13d5a6d9fde44cc1869a41f98d4c613b40

Go to SuiScan.xyz and find a list of modules under that package

#### NFT
mint(): find the created object in the console.
0xd306da35a34e2f6beee15560db3c16edb34d197b586efec62621c31d7fdbc109

#### Calculator

#### Fungible Coin
Published txn: https://suiscan.xyz/testnet/tx/GHKRgALtKfdUKvsR7NQoP4Pzfa5nCLp32Cc5dYcU9Ay5

Dragon Coin Object: https://suiscan.xyz/testnet/object/0x92207cdfe92222aab906fd3f54d3f8081b98e8f0ea76e481585589a321475d0b

Treasury Cap Object: https://suiscan.xyz/testnet/object/0x9127f84335a492a8b6784c1a684724be164caa5e5556b52c9b2b39f0de098921

Upgrade Cap: https://suiscan.xyz/testnet/object/0x0699476a1abfc6f2bbc65d427d2597ca590ccd196d2cffec93f4f572cb0b234f

#### Counter
https://suiscan.xyz/testnet/object/0xb65e5d600d777ea158d547ba8d840c82bfd1730ea2b6532fb525965da8d9370a