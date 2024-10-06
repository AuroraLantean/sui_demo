// from the Sui Move by Example book 
// (https://examples.sui.io/samples/coin.html)
// 
// coin module: https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/sui-framework/coin.md
module packagename::dragoncoin {
    
    use sui::coin;                          // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md
    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md
    use sui::url::{Self, Url};              // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/url.md
    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/tx_context.md

    /// The type identifier of coin. The coin will have a type tag of kind: 
    /// `Coin<package_object::dragoncoin::DRAGONCOIN>`
    /// Make sure that the name of the type matches the module's name.
    public struct DRAGONCOIN has drop {}

    /// Module initializer is called once on module publish. A treasury cap is sent to the 
    /// packagename, who then controls minting and burning
    //
    // coin::create_currency(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-create_currency
    // transfer::public_freeze_object(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md#function-public_freeze_object
    // transfer::public_transfer(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md#function-public_transfer
    fun init( witness: DRAGONCOIN, ctx: &mut TxContext) {
        // Function interface: public fun create_currency<T: drop>(witness: T, decimals: u8, symbol: vector<u8>, name: vector<u8>, description: vector<u8>, icon_url: option::Option<url::Url>, ctx: &mut tx_context::TxContext): (coin::TreasuryCap<T>, coin::CoinMetadata<T>)
        let (treasuryCap, metadata) = coin::create_currency(
            /*witnes=*/witness, 
            /*decimals=*/6, 
            /*symbol=*/b"DRAG", 
            /*name=*/b"Dragon coin", 
            /*description=*/b"Dragon coin is the one coin to rule them all", 
            /*icon_url=*/option::some<Url>(url::new_unsafe_from_bytes(b"https://peach-tough-crayfish-991.mypinata.cloud/ipfs/QmQyp2CSEi4m5YYfexrXM7TZzxXRfmrsqoasyBQwLxKY9q")), 
            /*ctx=*/ctx
        );
        
        // Freezes the object so the object becomes immutable, and non transferable
        //
        // Note: transfer::freeze_object() cannot be used since CoinMetadata is defined in another module
        transfer::public_freeze_object(metadata);

				//Turn the given object into a mutable shared object that everyone can access and mutate.
				//transfer::public_share_object(metadata);
        
        // Send the TreasuryCap object to the packagename of the module
        //
        // Note: transfer::transfer() cannot be used since TreasuryCap is defined in another module
        transfer::public_transfer(treasuryCap, tx_context::sender(ctx))
    }


    // coin::mint_and_transfer(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-mint_and_transfer
    // transfer::public_transfer(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md#function-public_transfer
    public entry fun mint
    (
        cap: &mut coin::TreasuryCap<packagename::dragoncoin::DRAGONCOIN>, 
        recipient: address,
        amount: u64, 
        ctx: &mut tx_context::TxContext
    )
    {
				//coin::mint_and_transfer(cap, amount, recipient, ctx);

        let new_coin = internal_mint_coin(cap, amount, ctx);

        // transfer the new coin to the recipient
        transfer::public_transfer(new_coin, recipient);
    }
    // This is the internal mint function. This function uses the Coin::mint function to create and return a new Coin object containing a balance of the given amount
    //
    // coin::mint(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-mint
    fun internal_mint_coin
    (
        cap: &mut coin::TreasuryCap<packagename::dragoncoin::DRAGONCOIN>, 
        amount: u64, 
        ctx: &mut tx_context::TxContext
    ): coin::Coin<packagename::dragoncoin::DRAGONCOIN>
    { 
        coin::mint(cap, amount, ctx)
    }
		
    // This function is an example of how internal_burn_coin() can be used.
    public entry fun burn
    (
        cap: &mut coin::TreasuryCap<packagename::dragoncoin::DRAGONCOIN>, 
        coin: coin::Coin<packagename::dragoncoin::DRAGONCOIN>
    )
    {
        // Note: internal_burn_coin returns a u64 but it can be ignored since u64 has drop
        internal_burn_coin(cap, coin);
    }
    // This is the internal burn function. This function uses the Coin::burn function to take a coin and destroy it. The function returns the amount of the coin that was destroyed.
    //
    // coin::burn(): hDRAGONCOINttps://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-burn
    fun internal_burn_coin
    (
        cap: &mut coin::TreasuryCap<packagename::dragoncoin::DRAGONCOIN>, 
        coin: coin::Coin<packagename::dragoncoin::DRAGONCOIN>
    ): u64
    {
        coin::burn(cap, coin)
    }
		
		#[test_only]
		public fun coin_init(ctx: &mut TxContext){
			init(DRAGONCOIN{}, ctx);
		}
}