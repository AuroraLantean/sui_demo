/*marketplace, where users can list items for sale, buy items, and collect profits from sales.*/
module package_addr::market {
	use sui::dynamic_field as df;
	use sui::coin::{Self, Coin};
	use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};

	//sui client publish --gas-budget 10000000000
	
	//Shared Object. Anyone can make this object with specified coin type
	public struct Market<phantom COIN> has key {
		id: UID,
		items: Bag,
		payments: Table<address, Coin<COIN>>,
	}
	// a single listing that specifies the item and price in Coin<COIN>
	public struct Listing has key, store {
		id: UID,
		ask: u64,
		owner: address,
	}
	const EAmountIncorrect: u64 = 0;
	const ENotOwner: u64 = 1;

	//make a new shared object: Market
	public entry fun new<COIN>(ctx: &mut TxContext) {
		transfer::share_object(	Market {
			id: object::new(ctx),
			items: bag::new(ctx),
			payments: table::new<address, Coin<COIN>>(ctx),
		});
	}
	
	//List an item in the Market
	public entry fun list_item<T: key + store, COIN>(
		market: &mut Market<COIN>,
		item: T, ask: u64, ctx: &mut TxContext
	){
		let item_id = object::id(&item);
		let mut listing = Listing {
			ask, id: object::new(ctx),
			owner: tx_context::sender(ctx),
		};
		df::add(&mut listing.id, true, item);
		bag::add(&mut market.items, item_id, listing);
	}
		//List an item in the Market
	/*public fun get_item<T: key + store, COIN>(
		market: &mut Market<COIN>,
		item: T, ask: u64, ctx: &mut TxContext
	){
		assert!( df::exists_(&house_data.id, game_id), EGameDoesNotExist);

		df::borrow(house_data.borrow(), game_id) 
	}*/

	//internal function to remove listing and return the listed item. Only owner is allowed
	fun delist<T: key + store, COIN>(
		market: &mut Market<COIN>,
		item_id: ID,
		ctx: &TxContext,
	): T {
		let Listing { id: mut idmut, owner, ask: _ } = bag::remove(&mut market.items, item_id);
		
		assert!(tx_context::sender(ctx) == owner, ENotOwner);
		let item = df::remove(&mut idmut, true);
		object::delete(idmut);
		item
	}
	
	// Call `delist` and transfer item to the sender
	public entry fun delist_and_take<T: key + store, COIN>(market: &mut Market<COIN>, item_id: ID, ctx: &mut TxContext){
		let item = delist<T, COIN>(market, item_id, ctx);
		transfer::public_transfer(item, tx_context::sender(ctx));
	}

	// Internal function to buy an item using a known Listing. Payment is done in Coin<COIN>. Amount paid must match the requested amount. Item seller gets the payment.
	fun buy<T: key + store, COIN>(market: &mut Market<COIN>, item_id: ID, paid: Coin<COIN>): T {
		let Listing {
			id, ask, owner
		} = bag::remove(&mut market.items, item_id);
		
		assert!(ask == coin::value(&paid), EAmountIncorrect);
		
		//Check if there is already a Coin hanging and merge `paid` with it. Otherwise, attach `paid` to the `Market` under owner's `address`
		let isFound = table::contains<address, Coin<COIN>>(&market.payments, owner);
		if(isFound){
			coin::join(table::borrow_mut<address, Coin<COIN>>(&mut market.payments, owner), paid);
		} else {
			table::add(&mut market.payments, owner, paid);
		};
		let mut idmut = id;
		let item = df::remove(&mut idmut, true);
		object::delete(idmut);
		item
	}
	
	// Call `buy` and transfer item to the sender
	public entry fun buy_and_take<T: key + store, COIN>(market: &mut Market<COIN>, item_id: ID, paid: Coin<COIN>, ctx: &mut TxContext){
		let obj = buy<T, COIN>(market, item_id, paid);
		transfer::public_transfer(obj, tx_context::sender(ctx));
	}
	
	//get sender's payemnt
	fun get_sender_payment<COIN>(market: &mut Market<COIN>, ctx: &TxContext): Coin<COIN>{
		table::remove<address, Coin<COIN>>(&mut market.payments, tx_context::sender(ctx))
	}
	//take profits from selling items
	public entry fun withdraw<COIN>(market: &mut Market<COIN>, recipient: address, ctx: &TxContext){
		let coin = get_sender_payment<COIN>(market, ctx);
		// let coin = coin::take(&mut shop.balc, amount, ctx);
		transfer::public_transfer(coin, recipient);
	}
	
	#[test_only]
	use sui::sui::SUI;
	#[test_only]
	use package_addr::dragoncoin::DRAGONCOIN;
	#[test_only]
	use package_addr::nft;
	#[test_only]
	use std::string::utf8;

	#[test]
	public fun test_market(){
		use sui::test_scenario as ts;
		use std::debug::print as p;
		
		let admin: address = @0xA;
		let user1: address = @0x001;
		let item_price = 137u64;
    let mut scenario_val = ts::begin(admin);
    let sn = &mut scenario_val;
		//make NFT item
		{
			p(&utf8(b"make NFT"));
			nft::mint(utf8(b"nft_name"), utf8(b"description"),
			vector[utf8(b"cat")],
			utf8(b"nft.com"),ts::ctx(sn));
		};
		
		//make a new market
		ts::next_tx(sn, admin);
		{
			p(&utf8(b"make a new market"));
			new<DRAGONCOIN>(ts::ctx(sn));
		};

		//list_item
		let item_id;
		ts::next_tx(sn, admin);
		{
			p(&utf8(b"list_item"));
			let mut market =  ts::take_shared<Market<DRAGONCOIN>>(sn);
			let nft_item = ts::take_from_sender<nft::Nft>(sn);
			item_id = object::id(&nft_item);

			list_item<nft::Nft, DRAGONCOIN>(
			&mut market,
			nft_item, 
			item_price, 
			ts::ctx(sn));
			ts::return_shared(market);
		};

		//buy_and_take
		ts::next_tx(sn, user1);
		{
			p(&utf8(b"buy_and_take"));
			let mut market =  ts::take_shared<Market<DRAGONCOIN>>(sn);
			
			let coin = coin::mint_for_testing<DRAGONCOIN>(item_price, ts::ctx(sn));

			buy_and_take<nft::Nft, DRAGONCOIN>(&mut market, item_id, coin, ts::ctx(sn));
			ts::return_shared(market);
		};

		//user1 checks received nft item
		ts::next_tx(sn, user1);
		{
			p(&utf8(b"user1 checks received nft item"));
			let nft_item = ts::take_from_sender<nft::Nft>(sn);
			assert!(nft::url(&nft_item) == utf8(b"nft.com"), 1);
			ts::return_to_sender(sn, nft_item);
		};

		//admin calls withdraw()
		ts::next_tx(sn, admin);
		{
			p(&utf8(b"admin calls withdraw()"));
			let mut market =  ts::take_shared<Market<DRAGONCOIN>>(sn);
			withdraw<DRAGONCOIN>(&mut market, admin, ts::ctx(sn));
			ts::return_shared(market);
		};

		//admin checks received payment
		ts::next_tx(sn, admin);
		{
			p(&utf8(b"admin checks received payment"));
			let coin = ts::take_from_sender<Coin<DRAGONCOIN>>(sn);//
			p(&coin::value(&coin));
			assert!(coin::value(&coin) == item_price, 1);
			ts::return_to_sender(sn, coin);
		};
		ts::end(scenario_val);
	}
}