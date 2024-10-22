// from the Sui Move by Example book 
// (https://examples.sui.io/samples/coin.html)
// 
// coin module: https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/sui-framework/coin.md
module package_addr::dragoncoin {
    
    use sui::coin::{Coin, value, TreasuryCap, create_currency, CoinMetadata, mint, burn, total_supply, get_decimals, get_name, get_symbol, get_description, get_icon_url,update_description};
		// https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md
    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md
    use sui::url::{Self, Url};              // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/url.md
    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/tx_context.md
		use std::string::String;
		use std::ascii;
    /// The type identifier of coin. The coin will have a type tag of kind: 
    /// `Coin<package_object::dragoncoin::DRAGONCOIN>`
    /// Make sure that the name of the type matches the module's name.
    public struct DRAGONCOIN has drop {}

    /// Module initializer is called once on module publish. A treasury cap is sent to the 
    /// package_addr, who then controls minting and burning
    //
    // create_currency(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-create_currency
    // transfer::public_freeze_object(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md#function-public_freeze_object
    // transfer::public_transfer(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md#function-public_transfer
    fun init( witness: DRAGONCOIN, ctx: &mut TxContext) {
        // Function interface: public fun create_currency<T: drop>(witness: T, decimals: u8, symbol: vector<u8>, name: vector<u8>, description: vector<u8>, icon_url: option::Option<url::Url>, ctx: &mut tx_context::TxContext): (TreasuryCap<T>, CoinMetadata<T>)
        let (treasuryCap, metadata) = create_currency(
            witness, 
            6, 
            b"DRAG", 
            b"Dragon coin", 
            b"Dragon coin is the one coin to rule them all", option::some<Url>(url::new_unsafe_from_bytes(b"icon_url"),), 
            ctx
        );//Optioin::none()
				//let (treasury, deny_cap, metadata) = coin::create_regulated_currency_v2(..)
        
        // Freezes the object so the object becomes immutable, and non transferable
        //
        // Note: transfer::freeze_object() cannot be used since CoinMetadata is defined in another module
				transfer::public_transfer(metadata, tx_context::sender(ctx));
        //transfer::public_freeze_object(metadata);

				//Turn the given object into a mutable shared object that everyone can access and mutate.
				//transfer::public_share_object(metadata);
        
				//transfer::public_transfer(deny_cap, ctx.sender());
        
				// Send the TreasuryCap object to the publisher. Note: transfer::transfer() cannot be used since TreasuryCap is defined in another module
        transfer::public_transfer(treasuryCap, tx_context::sender(ctx))
    }


    // coin::mint_and_transfer(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-mint_and_transfer
    // transfer::public_transfer(): https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/transfer.md#function-public_transfer
    public entry fun mint_coin
    (
        cap: &mut TreasuryCap<DRAGONCOIN>, 
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
        cap: &mut TreasuryCap<DRAGONCOIN>, 
        amount: u64, 
        ctx: &mut tx_context::TxContext
    ): Coin<DRAGONCOIN>
    { 
        mint(cap, amount, ctx)
    }
		
    // This function is an example of how internal_burn_coin() can be used.
    public entry fun burn_coin
    (
        cap: &mut TreasuryCap<DRAGONCOIN>, 
        coin: Coin<DRAGONCOIN>
    )
    {
        // Note: internal_burn_coin returns a u64 but it can be ignored since u64 has drop
        internal_burn_coin(cap, coin);
    }
    // This is the internal burn function. This function uses the Coin::burn function to take a coin and destroy it. The function returns the amount of the coin that was destroyed.
    //
    // burn(): hDRAGONCOINttps://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/coin.md#function-burn
    fun internal_burn_coin
    (
        cap: &mut TreasuryCap<DRAGONCOIN>, 
        coin: Coin<DRAGONCOIN>
    ): u64
    {
        burn(cap, coin)
    }
		
		public fun get_total_supply(cap: & TreasuryCap<DRAGONCOIN>): u64 {
			total_supply(cap)
		}
		public fun get_decimals_coin(metadata: & CoinMetadata<DRAGONCOIN>): u8 {
			get_decimals(metadata)
		}
		public fun get_name_coin(metadata: & CoinMetadata<DRAGONCOIN>): String {
			get_name(metadata)
		}
		public fun get_symbol_coin(metadata: & CoinMetadata<DRAGONCOIN>): ascii::String {
			get_symbol(metadata)
		}
		public fun get_description_coin(metadata: & CoinMetadata<DRAGONCOIN>): String {
			get_description(metadata)
		}
		public fun get_icon_url_coin(metadata: & CoinMetadata<DRAGONCOIN>): Option<sui::url::Url> {
			get_icon_url(metadata)
		}
		
		public fun update_description_coin(treasury_cap: & TreasuryCap<DRAGONCOIN>, metadata: &mut CoinMetadata<DRAGONCOIN>, description_new: String) {
			update_description(treasury_cap, metadata, description_new)
		}
		
		/*//docs::/#regulate}
    public fun add_addr_from_deny_list(
        denylist: &mut DenyList,
        denycap: &mut DenyCapV2<REGCOIN>,
        denyaddy: address,
        ctx: &mut TxContext,
    ) {
        coin::deny_list_v2_add(denylist, denycap, denyaddy, ctx);
    }

    public fun remove_addr_from_deny_list(
        denylist: &mut DenyList,
        denycap: &mut DenyCapV2<REGCOIN>,
        denyaddy: address,
        ctx: &mut TxContext,
    ) {
        coin::deny_list_v2_remove(denylist, denycap, denyaddy, ctx);
    }*/

	#[test_only]
	use std::string::utf8;

	#[test]
	public fun test_coin(){
		use sui::test_scenario as ts;
		use std::debug::print as p;
		
		let admin: address = @0xA;
		let user1: address = @0x001;
    let mut scenario_val = ts::begin(admin);
    let sn = &mut scenario_val;
		{
			init(DRAGONCOIN{}, ts::ctx(sn));
		};
		let amount = 1000;
		//check the cap
		ts::next_tx(sn, admin);
		{
			let mut cap = ts::take_from_sender<TreasuryCap<DRAGONCOIN>>(sn);
			let total_supply = get_total_supply(&cap);
			p(&total_supply);
			assert!(total_supply == 0, 1);
			
			mint_coin(&mut cap, user1, amount, ts::ctx(sn));
			
			let total_supply = get_total_supply(&cap);
			p(&total_supply);
			assert!(total_supply == amount, 1);
			ts::return_to_sender(sn, cap);
		};

		ts::next_tx(sn, user1);
		{
			let coin = ts::take_from_sender<Coin<DRAGONCOIN>>(sn);//
			p(&value(&coin));
			assert!(value(&coin) == amount, 1);
			//ts::return_to_sender(sn, coin);

			let mut cap = ts::take_from_address<TreasuryCap<DRAGONCOIN>>(sn, admin);
			burn_coin(&mut cap, coin);
			ts::return_to_address(admin, cap);
		};

		//ts::next_tx(sn, user1);{	};
		//check the metadata
		ts::next_tx(sn, admin);
		{
			let metadata = ts::take_from_sender<CoinMetadata<DRAGONCOIN>>(sn);
			let decimals = get_decimals_coin(&metadata);
			p(&decimals);
			assert!(decimals == 6, 1);

			let name = get_name_coin(&metadata);
			p(&name);
			assert!(name == utf8(b"Dragon coin"), 1);

			let descriptn = get_description_coin(&metadata);
			p(&descriptn);
			assert!(descriptn == utf8(b"Dragon coin is the one coin to rule them all"), 1);

			let url = get_icon_url_coin(&metadata).extract().inner_url();//sui::url::Url
			p(&url);
			assert!(url == (b"icon_url").to_ascii_string(), 1);

			let symbol = get_symbol_coin(&metadata);
			p(&symbol);
			assert!(symbol == (b"DRAG").to_ascii_string(), 1);
			
			ts::return_to_sender(sn, metadata);
		};
		
		//update the metadata
		ts::next_tx(sn, admin);
		{
			let cap = ts::take_from_sender<TreasuryCap<DRAGONCOIN>>(sn);
			let mut metadata = ts::take_from_sender<CoinMetadata<DRAGONCOIN>>(sn);
			let new_description = utf8(b"new_description");
			update_description_coin(&cap, &mut metadata, new_description);
			
			ts::return_to_sender(sn, cap);
			ts::return_to_sender(sn, metadata);
		};
		ts::end(scenario_val);
	}
}
