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
	//use sui::balance::{Self, Balance};

	public struct UserData<Coin> has store, copy {
		bets: vector<Coin>,
	}
	//Shared Object. Anyone can make this
	public struct Prediction<phantom COIN> has key {
		id: UID,
		choices: vector<String>,
		users: Table<address, UserData<Coin<COIN>>>,
	}

	const EAmountTooSmall: u64 = 0;
	const EAmountTooBig: u64 = 1;
	const EChoiceInvalid: u64 = 1;
	const ENotOwner: u64 = 10;
	
	//make a new shared object: Prediction
	public entry fun new<COIN>(choice1: String,choice2: String, choice3: String, choice4: String, ctx: &mut TxContext) {
		
		transfer::share_object(	Prediction {
			id: object::new(ctx),
			choices: vector[choice1, choice2, choice3, choice4],
			users: table::new<address, UserData<Coin<COIN>>>(ctx),
		});
	}

	// Internal function to bet
	public entry fun bet<COIN>(prediction: &mut Prediction<COIN>, amount: u64, mut gasCoinId: Coin<COIN>, choice: u64, ctx: &mut TxContext) {

		assert!(gasCoinId.value() >= amount , EAmountTooSmall);
		assert!(choice <= 3, EChoiceInvalid);
		let sender = ctx.sender();
		
//public fun split<T>(self: &mut Coin<T>, split_amount: u64, ctx: &mut TxContext)
//let mut stake = gasCoinId.into_balance();
		let bet_amt = gasCoinId.split(amount, ctx);

		let isFound = table::contains<address, UserData<Coin<COIN>>>(&prediction.users, sender);
		
		if(isFound){
			let user_data = table::borrow_mut<address, UserData<Coin<COIN>>>(&mut prediction.users, sender);
			
			let value = vector::borrow_mut(&mut user_data.bets, choice);
			
			coin::join(value, bet_amt);

		} else {
			let mut user_data = UserData<Coin<COIN>> {
				bets: vector<Coin<COIN>>[coin::zero<COIN>(ctx), coin::zero<COIN>(ctx), coin::zero<COIN>(ctx), coin::zero<COIN>(ctx)],
			};
			let value = vector::borrow_mut(&mut user_data.bets, choice);
			coin::join(value, bet_amt);
			
			table::add(&mut prediction.users, sender, user_data);
		};
		transfer::public_transfer(gasCoinId, sender);
	}
	
	// === Tests ===
	#[test_only] use sui::sui::SUI;
	#[test_only] use sui::test_scenario::{Self as ts, Scenario};
	#[test_only] use std::debug::print as p;
			
	#[test_only]
	fun mint(ts: &mut Scenario): Coin<SUI> {
		coin::mint_for_testing<SUI>(1000, ts.ctx())
	}

	#[test]
	fun test_init_prediction() {
		let admin: address = @0xA;
		let user1: address = @0x001;
		let mut sval = ts::begin(admin);
		let sn = &mut sval;
		let coin = mint(sn);

		let amount = 1000;
		{
			new<SUI>(utf8(b"BITCOIN"), utf8(b"choice2"), utf8(b"choice3"), utf8(b"choice4"), ts::ctx(sn));
		};
		
		coin.burn_for_testing();
		sval.end();
	}
}