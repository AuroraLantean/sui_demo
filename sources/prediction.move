/*Any user can make a new game with a list of options, then the user himself(game owner) and other users can bet on one/some/all option(s).

After some time, the game owner can settle the game outcome and withdraw fees.
And users who bet can claim rewards if they win.*/
module package_addr::prediction {
	//use sui::dynamic_field as df;
	use sui::coin::{Self, Coin};
	use sui::transfer;
	//use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};
	use std::string::{utf8, String};

	//Shared Object. Anyone can make this object with specified coin type
	public struct Prediction<phantom COIN> has key {
		id: UID,
		choices: vector<String>,
		bets: Table<address, Coin<COIN>>,
	}

	const EAmountTooSmall: u64 = 0;
	const EAmountTooBig: u64 = 1;
	const ENotOwner: u64 = 10;
	
	//make a new shared object: Prediction
	public entry fun new<COIN>(choice1: String,choice2: String, choice3: String, choice4: String,ctx: &mut TxContext) {
		transfer::share_object(	Prediction {
			id: object::new(ctx),
			choices: vector[choice1, choice2, choice3, choice4],
			bets: table::new<address, Coin<COIN>>(ctx),
		});
	}

	// Internal function to bet
	public entry fun bet<COIN>(prediction: &mut Prediction<COIN>, amount: u64, mut gasCoinId: Coin<COIN>, ctx: &mut TxContext) {

		assert!(gasCoinId.value() >= amount , EAmountTooSmall);
		let sender = ctx.sender();
		
//public fun split<T>(self: &mut Coin<T>, split_amount: u64, ctx: &mut TxContext)
//let mut stake = gasCoinId.into_balance();
		let bet_amt = gasCoinId.split(amount, ctx);

		let isFound = table::contains<address, Coin<COIN>>(&prediction.bets, sender);
		if(isFound){
			coin::join(table::borrow_mut<address, Coin<COIN>>(&mut prediction.bets, sender), bet_amt);
		} else {
			table::add(&mut prediction.bets, sender, bet_amt);
		};
		transfer::public_transfer(gasCoinId, sender);
	}
}