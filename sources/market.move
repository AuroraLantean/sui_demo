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
		let mut gameListing = Listing {
			ask, id: object::new(ctx),
			owner: tx_context::sender(ctx),
		};
		df::add(&mut gameListing.id, true, item);
		bag::add(&mut market.items, item_id, gameListing);
	}
	
	//internal function to remove listing and return the listed item. Only owner is allowed
	fun delist<T: key + store, COIN>(
		market: &mut Market<COIN>,
		item_id: ID,
		ctx: &TxContext,
	): T {
		let Listing { id, owner, ask: _ } = bag::remove(&mut market.items, item_id);
		let mut idmut = id;
		
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
	
	//take profits from selling items
	public fun withdraw<COIN>(market: &mut Market<COIN>, ctx: &TxContext): Coin<COIN>{
		table::remove<address, Coin<COIN>>(&mut market.payments, tx_context::sender(ctx))
		//transfer::public_transfer(coin, ctx.sender());
	}
	
}