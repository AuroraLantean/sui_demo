/*game item marketplace, where users can list items for sale, buy items, and collect profits from sales.*/
module package_addr::gameMarket {
	use sui::dynamic_field as ofield;
	use sui::coin::{Self, Coin};
	use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};

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
	

}