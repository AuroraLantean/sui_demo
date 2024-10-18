/*game item marketplace, where users can list items for sale, buy items, and collect profits from sales.*/
module package_addr::gameMarket {
	use sui::dynamic_field as ofield;
	use sui::coin::{Self, Coin};
	use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};

	//sui client publish --gas-budget 10000000000
	
	//Shared Object. Anyone can make this object with specified coin type
	public struct GameMarket<phantom COIN> has key {
		id: UID,
		gameItems: Bag,
		payments: Table<address, Coin<COIN>>,
	}
	// a single listing that specifies the item and price in Coin<COIN>
	public struct GameListing has key, store {
		id: UID,
		ask: u64,
		owner: address,
	}
	const EAmountIncorrect: u64 = 0;
	const ENotOwner: u64 = 1;

	//make a new shared object: GameMarket
	public entry fun new<COIN>(ctx: &mut TxContext) {
		transfer::share_object(	GameMarket {
			id: object::new(ctx),
			gameItems: bag::new(ctx),
			payments: table::new<address, Coin<COIN>>(ctx),
		});
	}
	
	//List an item in the GameMarket
	public entry fun list_item<T: key + store, COIN>(
		gameMarket: &mut GameMarket<COIN>,
		item: T, ask: u64, ctx: &mut TxContext
	){
		let item_id = object::id(&item);
		let mut gameListing = GameListing {
			ask, id: object::new(ctx),
			owner: tx_context::sender(ctx),
		};
		ofield::add(&mut gameListing.id, true, item);
		bag::add(&mut gameMarket.gameItems, item_id, gameListing);
	}
	
	//internal function to remove listing and return the listed item. Only owner is allowed
	fun delist<T: key + store, COIN>(
		gameMarket: &mut GameMarket<COIN>,
		item_id: ID,
		ctx: &TxContext,
	): T {
		let GameListing { id, owner, ask: _ } = bag::remove(&mut gameMarket.gameItems, item_id);
		let mut idmut = id;
		
		assert!(tx_context::sender(ctx) == owner, ENotOwner);
		let item = ofield::remove(&mut idmut, true);
		object::delete(idmut);
		item
	}
	
	// Call `delist` and transfer item to the sender
	public entry fun delist_and_take<T: key + store, COIN>(gameMarket: &mut GameMarket<COIN>, item_id: ID, ctx: &mut TxContext){
		let item = delist<T, COIN>(gameMarket, item_id, ctx);
		transfer::public_transfer(item, tx_context::sender(ctx));
	}

	// Internal function to buy an item using a known GameListing. Payment is done in Coin<COIN>. Amount paid must match the requested amount. Item seller gets the payment.
	fun buy<T: key + store, COIN>(gameMarket: &mut GameMarket<COIN>, item_id: ID, paid: Coin<COIN>): T {
		let GameListing {
			id, ask, owner
		} = bag::remove(&mut gameMarket.gameItems, item_id);
		
		assert!(ask == coin::value(&paid), EAmountIncorrect);
		
		//Check if there is already a Coin hanging and merge `paid` with it. Otherwise, attach `paid` to the `GameMarket` under owner's `address`
		let isFound = table::contains<address, Coin<COIN>>(&gameMarket.payments, owner);
		if(isFound){
			coin::join(table::borrow_mut<address, Coin<COIN>>(&mut gameMarket.payments, owner), paid);
		} else {
			table::add(&mut gameMarket.payments, owner, paid);
		};
		let mut idmut = id;
		let item = ofield::remove(&mut idmut, true);
		object::delete(idmut);
		item
	}
	
	// Call `buy` and transfer item to the sender
	public entry fun buy_and_take<T: key + store, COIN>(gameMarket: &mut GameMarket<COIN>, item_id: ID, paid: Coin<COIN>, ctx: &mut TxContext){
		let obj = buy<T, COIN>(gameMarket, item_id, paid);
		transfer::public_transfer(obj, tx_context::sender(ctx));
	}
	
	//Internal function to take profits from selling items
	public fun withdraw<COIN>(gameMarket: &mut GameMarket<COIN>, ctx: &TxContext): Coin<COIN>{
		table::remove<address, Coin<COIN>>(&mut gameMarket.payments, tx_context::sender(ctx))
	}
}