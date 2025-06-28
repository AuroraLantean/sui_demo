/*marketplace, where users can list items for sale, buy items, and collect profits from sales.*/
module package_addr::market;
	use sui::dynamic_field as df;
	use sui::coin::{Self, Coin};
	use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};
  //use std::debug::print;

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
			owner: ctx.sender(),
		};
		df::add(&mut listing.id, true, item);
		bag::add(&mut market.items, item_id, listing);
	}
		//List an item in the Market
	/*public fun get_item<T: key + store, COIN>(
		market: &mut Market<COIN>,
		item: T, ask: u64, ctx: &mut TxContext
	){
		assert!(df::exists_(&house_data.id, game_id), EGameDoesNotExist);

		df::borrow(house_data.borrow(), game_id) 
	}*/

	//internal function to remove listing and return the listed item. Only owner is allowed
	fun delist<T: key + store, COIN>(
		market: &mut Market<COIN>,
		item_id: ID,
		ctx: &TxContext,
	): T {
		let Listing { id: mut idmut, owner, ask: _ } = bag::remove(&mut market.items, item_id);
		
		assert!(ctx.sender() == owner, ENotOwner);
		let item = df::remove(&mut idmut, true);
		object::delete(idmut);
		item
	}
	
	// Call `delist` and transfer item to the sender
	public entry fun delist_and_take<T: key + store, COIN>(market: &mut Market<COIN>, item_id: ID, ctx: &mut TxContext){
		let item = delist<T, COIN>(market, item_id, ctx);
		transfer::public_transfer(item, ctx.sender());
	}

	// Internal function to buy an item using a known Listing. Payment is done in Coin<COIN>. Amount paid must match the requested amount. Item seller gets the payment.
	fun buy<T: key + store, COIN>(market: &mut Market<COIN>, item_id: ID, paid: Coin<COIN>): T {
		let Listing {
			mut id, ask, owner
		} = bag::remove(&mut market.items, item_id);
		
		assert!(ask == coin::value(&paid), EAmountIncorrect);
		
		//Check if there is already a Coin hanging and merge `paid` with it. Otherwise, attach `paid` to the `Market` under owner's `address`
		let isFound = table::contains<address, Coin<COIN>>(&market.payments, owner);
		if(isFound){
			coin::join(table::borrow_mut<address, Coin<COIN>>(&mut market.payments, owner), paid);
		} else {
			table::add(&mut market.payments, owner, paid);
		};
		let item = df::remove(&mut id, true);
		object::delete(id);
		item
	}
	
	// Call `buy` and transfer item to the sender
	public entry fun buy_and_take<T: key + store, COIN>(market: &mut Market<COIN>, item_id: ID, paid: Coin<COIN>, ctx: &mut TxContext){
		let item = buy<T, COIN>(market, item_id, paid);
		transfer::public_transfer(item, ctx.sender());
	}
	
	//get sender's payemnt
	fun get_sender_payment<COIN>(market: &mut Market<COIN>, ctx: &TxContext): Coin<COIN>{
		table::remove<address, Coin<COIN>>(&mut market.payments, ctx.sender())
	}
	//take profits from selling items
	public entry fun withdraw<COIN>(market: &mut Market<COIN>, recipient: address, ctx: &TxContext){
    //print(&utf8(b"withdraw(1)"));
		let coin = get_sender_payment<COIN>(market, ctx);
		// let coin = coin::take(&mut shop.balc, amount, ctx);
    //print(&utf8(b"withdraw(2)"));
		transfer::public_transfer(coin, recipient);
	}
	
	//#[test_only]
	//use sui::sui::SUI;
	#[test_only] use package_addr::dragon::DRAGON;
	#[test_only] use package_addr::nft;
	#[test_only] use std::string::utf8;
  #[test_only] use std::debug::print;
  #[test_only] use sui::test_scenario::{begin, return_shared, return_to_sender};
  #[test_only]
  public fun pp(bytes: vector<u8>) {
    print(&utf8(bytes));
  }
	#[test]
	public fun test_market(){
	
		let admin: address = @0xAd;
		let adam: address = @0xa0;
		let bob: address = @0xb0;
		let item_price = 137u64;

		//admin: make a new market
    let mut sce = begin(admin);
		{
			pp(b"admin: make a new market");
			new<DRAGON>(sce.ctx());
		};

		//adam: make NFT item
		sce.next_tx(adam);
		{
			pp(b"adam: make NFT");
			nft::mint(utf8(b"nft_name"), utf8(b"description"),
			vector[utf8(b"cat")],
			utf8(b"nft.com"),sce.ctx());
		};
    
		//adam: list the NFT item
		let item_id;
		sce.next_tx(adam);
		{
			pp(b"adam: list_the NFT item");
			let mut market =  sce.take_shared<Market<DRAGON>>();

			let nft_item = sce.take_from_sender<nft::Nft>();
			item_id = object::id(&nft_item);

			list_item<nft::Nft, DRAGON>(
			&mut market,
			nft_item, 
			item_price, 
			sce.ctx());
			return_shared(market);
		};

		//bob: get money, buy_and_take
		sce.next_tx(bob);
		{
			pp(b"bob: get money, buy_and_take");
			let mut market =  sce.take_shared<Market<DRAGON>>();
			
			let coin = coin::mint_for_testing<DRAGON>(item_price, sce.ctx());

			buy_and_take<nft::Nft, DRAGON>(&mut market, item_id, coin, sce.ctx());
			return_shared(market);
		};

		//bob: check received nft item
		sce.next_tx(bob);
		{
			pp(b"bob: check received nft item");
			let nft_item = sce.take_from_sender<nft::Nft>();
			assert!(nft::url(&nft_item) == utf8(b"nft.com"), 1);
			sce.return_to_sender(nft_item);
		};

		//adam: withdraw payment
		sce.next_tx(adam);
		{
			pp(b"adam: withdraw payment");
			let mut market =  sce.take_shared<Market<DRAGON>>();

			withdraw<DRAGON>(&mut market, adam, sce.ctx());
			return_shared(market);
		};

		//adam: check received payment
		sce.next_tx(adam);
		{
			pp(b"adam: check received payment");
			let coin = sce.take_from_sender<Coin<DRAGON>>();//
			print(&coin::value(&coin));
			assert!(coin::value(&coin) == item_price, 1);
			sce.return_to_sender(coin);
		};
		sce.end();
	}
