// from the Sui Move by Example book 
// (https://examples.sui.io/samples/coin.html)
// docs: https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/docs/sui
module package_addr::dragoncoin;
    
    use sui::coin::{Self, Coin, TreasuryCap, CoinMetadata};
    use sui::url::{Self, Url};
		use std::string::String;
		use std::ascii;
    /// Coin type = Coin<package_object::dragoncoin::DRAGONCOIN
    
    const EInvalidAmount: u64 = 0;
    const ESupplyExceeded: u64 = 1;

    /// Make sure that the name of the type matches the module's name.
    public struct DRAGONCOIN has drop {}

    #[test_only]
    public fun new_otw(_ctx: &mut TxContext): DRAGONCOIN {
      DRAGONCOIN {}
    }

    public struct MintCapability has key {
        id: UID,
        total_minted: u64,
    }

    const TOTAL_SUPPLY: u64 = 1_000_000_000_000_000_000;//includes decimal zeros
    const INITIAL_SUPPLY: u64 = 100_000_000_000_000_000;
    //const COMMUNITY_SUPPLY: u64 = 700_000_000_000_000_000;

    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/sui/coin.md#function-create_currency
    fun init( witness: DRAGONCOIN, ctx: &mut TxContext) {
        let (mut treasuryCap, metadata) = coin::create_currency(
            witness, 
            9, 
            b"DRAG", 
            b"Dragon coin", 
            b"Dragon coin is the one coin to rule them all", option::some<Url>(url::new_unsafe_from_bytes(b"https://dukudama.sirv.com/Images/dragonGold001-512x512.png"),), 
            ctx
        );//b"data:image/jpeg;base64,DATA"  ... DATA is from $ base64 -i your_image.jpg | pbcopy
        
        let mut mint_cap = MintCapability {
          id: object::new(ctx),
          total_minted: 0,
        };
        mint(&mut treasuryCap, &mut mint_cap, INITIAL_SUPPLY, ctx.sender(), ctx);
        //mint(&mut treasury, COMMUNITY_SUPPLY, @community_wallet, ctx);

        //Optioin::none()
        transfer::public_freeze_object(metadata);
        //transfer::public_transfer(metadata, tx_context::sender(ctx));
        
        //transfer::public_freeze_object(treasuryCap);
        transfer::public_transfer(treasuryCap, ctx.sender());
        transfer::transfer(mint_cap, ctx.sender());
    }
    
		#[test_only]
    public fun new( witness: DRAGONCOIN, ctx: &mut TxContext) {
			init( witness, ctx);
		}

    // https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/sui/coin.md#sui_coin_mint
    public entry fun mint
    (
        cap: &mut TreasuryCap<DRAGONCOIN>,
        mint_cap: &mut MintCapability,
        amount: u64, 
        recipient: address,
        ctx: &mut tx_context::TxContext
    )
    {
        assert!(amount > 0, EInvalidAmount);
        assert!(mint_cap.total_minted + amount <= TOTAL_SUPPLY, ESupplyExceeded);
        
        let new_coin = coin::mint(cap, amount, ctx);

        transfer::public_transfer(new_coin, recipient);
        //coin::mint_and_transfer(cap, amount, recipient, ctx);
        mint_cap.total_minted = mint_cap.total_minted + amount;
    }

    public entry fun burn
    (
        cap: &mut TreasuryCap<DRAGONCOIN>, 
        coin: Coin<DRAGONCOIN>
    ): u64
    {
        coin::burn(cap, coin)
    }

    public fun join(coin1: &mut Coin<DRAGONCOIN>, coin2: Coin<DRAGONCOIN>): &mut Coin<DRAGONCOIN> {
        coin::join( coin1, coin2);
				coin1
    }

    public fun split(coin: &mut Coin<DRAGONCOIN>, amount: u64, ctx: &mut TxContext): Coin<DRAGONCOIN> {
        coin::split(coin, amount, ctx)
    }
		
		public fun get_total_supply(cap: & TreasuryCap<DRAGONCOIN>): u64 {
			coin::total_supply(cap)
		}
		public fun get_decimals_coin(metadata: & CoinMetadata<DRAGONCOIN>): u8 {
			coin::get_decimals(metadata)
		}
		public fun get_name_coin(metadata: & CoinMetadata<DRAGONCOIN>): String {
			coin::get_name(metadata)
		}
		public fun get_symbol_coin(metadata: & CoinMetadata<DRAGONCOIN>): ascii::String {
			coin::get_symbol(metadata)
		}
		public fun get_description_coin(metadata: & CoinMetadata<DRAGONCOIN>): String {
			coin::get_description(metadata)
		}
		public fun get_icon_url_coin(metadata: & CoinMetadata<DRAGONCOIN>): Option<sui::url::Url> {
			coin::get_icon_url(metadata)
		}
		
		public fun update_description_coin(treasury_cap: & TreasuryCap<DRAGONCOIN>, metadata: &mut CoinMetadata<DRAGONCOIN>, description_new: String) {
			coin::update_description(treasury_cap, metadata, description_new)
		}
	
#[test_only]
use sui::test_scenario;

#[test]
fun test_init() {
    let publisher = @0x11;
    let mut scenario = test_scenario::begin(publisher);
    {
        let otw = DRAGONCOIN{};
        init(otw, scenario.ctx());
    };

    scenario.next_tx(publisher);
    {
        let mint_cap = scenario.take_from_sender<MintCapability>();

        let coins = scenario.take_from_sender<coin::Coin<DRAGONCOIN>>();

        assert!(mint_cap.total_minted == INITIAL_SUPPLY, EInvalidAmount);
        assert!(coins.balance().value() == INITIAL_SUPPLY, EInvalidAmount);

        scenario.return_to_sender(coins);
        scenario.return_to_sender(mint_cap);
    };
    
    scenario.next_tx(publisher);
    {
        let mut treasury_cap = scenario.take_from_sender<TreasuryCap<DRAGONCOIN>>();

        let mut mint_cap = scenario.take_from_sender<MintCapability>();

        mint(
            &mut treasury_cap,
            &mut mint_cap,
            900_000_000_000_000_000,
            scenario.ctx().sender(),
            scenario.ctx()
        );

        assert!(mint_cap.total_minted == TOTAL_SUPPLY, EInvalidAmount);
        scenario.return_to_sender(treasury_cap);
        scenario.return_to_sender(mint_cap);
    };


    scenario.end();
}

/*// === Tests ===
	#[test_only] use sui::coin::value;
	#[test_only] use std::string::utf8;

	#[test]
	public fun test_coin(){
		use sui::test_scenario::{begin, return_to_address};
		use std::debug::print as pp;
		
		let admin: address = @0xAd;
		let user1: address = @0x001;
    let mut tss = begin(admin);
    //let sn = &mut tss;
		{
			init(DRAGONCOIN{}, tss.ctx());
		};
		let amount = 1000;
		//check the cap
		tss.next_tx(admin);
		{
			let mut cap = tss.take_from_sender<TreasuryCap<DRAGONCOIN>>();
			let total_supply = get_total_supply(&cap);
			pp(&total_supply);
			assert!(total_supply == 0, 1);
			
			mint(&mut cap,  &mut mint_cap, amount, user1, tss.ctx());
			
			let total_supply = get_total_supply(&cap);
			pp(&total_supply); 
			assert!(total_supply == amount, 1);
			tss.return_to_sender(cap);
		};

		tss.next_tx( user1);
		{
			let coin = tss.take_from_sender<Coin<DRAGONCOIN>>();//
			pp(&value(&coin));
			assert!(value(&coin) == amount, 1);
			//tss.return_to_sender(sn, coin);

			let mut cap = tss.take_from_address<TreasuryCap<DRAGONCOIN>>( admin);
			burn(&mut cap, coin);
      
			return_to_address<TreasuryCap<DRAGONCOIN>>(admin, cap);
		};

		//tss.next_tx(sn, user1);{	};
		//check the metadata
		tss.next_tx(admin);
		{
			let metadata = tss.take_from_sender<CoinMetadata<DRAGONCOIN>>();
			let decimals = get_decimals_coin(&metadata);
			pp(&decimals);
			assert!(decimals == 6, 1);

			let name = get_name_coin(&metadata);
			pp(&name);
			assert!(name == utf8(b"Dragon coin"), 1);

			let descriptn = get_description_coin(&metadata);
			pp(&descriptn);
			assert!(descriptn == utf8(b"Dragon coin is the one coin to rule them all"), 1);

			let url = get_icon_url_coin(&metadata).extract().inner_url();//sui::url::Url
			pp(&url);
			assert!(url == (b"icon_url").to_ascii_string(), 1);

			let symbol = get_symbol_coin(&metadata);
			pp(&symbol);
			assert!(symbol == (b"DRAG").to_ascii_string(), 1);
			
			tss.return_to_sender(metadata);
		};
		
		//update the metadata
		tss.next_tx( admin);
		{
			let cap = tss.take_from_sender<TreasuryCap<DRAGONCOIN>>();
			let mut metadata = tss.take_from_sender<CoinMetadata<DRAGONCOIN>>();
			let new_description = utf8(b"new_description");
			update_description_coin(&cap, &mut metadata, new_description);
			
			tss.return_to_sender( cap);
			tss.return_to_sender( metadata);
		};
		tss.end();
	}
}*/