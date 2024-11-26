/*Any user can make a new game with a list of options, then the user himself(game owner) and other users can bet on one/some/all option(s).

After some time, the game owner can settle the game outcome and withdraw fees.
And users who bet can claim rewards if they win.*/
module package_addr::prediction {
	//use sui::dynamic_field as df;
	use sui::coin::{Self, Coin};
	//use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};
	use std::string::{utf8, String};
	//use sui::balance::{Self, Balance};
	use 0x1::option::{some, is_some, none, extract};

	public struct UserData<Coin> has store, copy {
		bets: vector<Coin>,
	}
	//Shared Object. Anyone can make this
	public struct Prediction<phantom COIN> has key {
		id: UID,
		owner: address,
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
			owner: ctx.sender(),
			choices: vector[choice1, choice2, choice3, choice4],
			users: table::new<address, UserData<Coin<COIN>>>(ctx),
		});
	}

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
	
	public fun get_user<COIN>(prediction: &Prediction<COIN>, user: address, index: u64): u64 {

		let isFound = table::contains<address, UserData<Coin<COIN>>>(&prediction.users, user);
		
		//let user_data: option<UserData<Coin<COIN>>> = 
		if(!isFound){
			return 0;
		};
		let user_data = table::borrow<address, UserData<Coin<COIN>>>(&prediction.users, user);

		//let bets = user_data.bets;
		let coin = vector::borrow(&user_data.bets, index);//sui::coin::Coin<sui::sui::SUI>
		coin.value()
	}
	
	// === Tests ===
	#[test_only] use sui::sui::SUI;
	#[test_only] use sui::coin::value;
	#[test_only] use sui::test_scenario::{Self as ts, Scenario};
	#[test_only] use std::debug::print as prt;
			
	#[test_only]
	fun mint(sn: &mut Scenario, amount: u64): Coin<SUI> {
		coin::mint_for_testing<SUI>(amount, sn.ctx())
	}

	#[test]
	fun test_init_prediction() {
		let admin: address = @0xA;
		let user1: address = @0x001;
		let user2: address = @0x002;
		let user3: address = @0x003;
		let mut tsv = ts::begin(admin);
		{
			new<SUI>(utf8(b"Bitcoin"), utf8(b"Ethereum"), utf8(b"Solana"), utf8(b"Sui"), tsv.ctx());
		};
		
		// read prediction object
		{
			tsv.next_tx(admin);
			let prediction: Prediction<SUI> = tsv.take_shared();
			prt(&prediction);
			assert!(prediction.owner == admin);
			assert!(prediction.choices[0] == utf8(b"Bitcoin"));
			ts::return_shared(prediction);
		};

		let init_amt: u64 = 1000;
		let bet_amt1: u64 = 123;
		let user1_choice: u64 = 0;
		// user1 bets on prediction
		{
			tsv.next_tx(user1);
			let mut prediction: Prediction<SUI> = tsv.take_shared();
			let coin1 = mint(&mut tsv, init_amt);
			//let coin = ts::take_from_sender<Coin<SUI>>(&mut tsv);
			prt(&utf8(b"User1 has balance:"));
			prt(&value(&coin1));
			assert!(value(&coin1) == init_amt, 1);
		
			//invoke bet()
			bet<SUI>(&mut prediction, bet_amt1, coin1, user1_choice, tsv.ctx());
			//coin1.burn_for_testing();
			ts::return_shared(prediction);
		};
		
		// read prediction object
		/*id: UID,
		owner: address,
		choices: vector<String>,
		users: Table<address, UserData<Coin<COIN>>>,*/
		{
			tsv.next_tx(user2);
			let prediction: Prediction<SUI> = tsv.take_shared();
			prt(&prediction);

			let amount = get_user<SUI>(&prediction, user1, user1_choice);
			prt(&utf8(b"User1 has bet:"));
			prt(&amount);
			assert!(amount == bet_amt1);
			ts::return_shared(prediction);
		};
		
		// user1 bets on prediction again
		{
			tsv.next_tx(user1);
			let mut prediction: Prediction<SUI> = tsv.take_shared();

			let coin1 = mint(&mut tsv, init_amt);
			/*prt(&utf8(b"User1 has balance:"));
			prt(&value(&coin1));
			assert!(value(&coin1) == (init_amt-bet_amt1), 1);*/
		
			//invoke bet()
			bet<SUI>(&mut prediction, bet_amt1, coin1, user1_choice, tsv.ctx());
			//coin1.burn_for_testing();
			ts::return_shared(prediction);
		};
		{
			tsv.next_tx(user2);
			let prediction: Prediction<SUI> = tsv.take_shared();
			prt(&prediction);

			let amount = get_user<SUI>(&prediction, user1, user1_choice);
			prt(&utf8(b"User1 has bet:"));
			prt(&amount);
			assert!(amount == bet_amt1*2);
			ts::return_shared(prediction);
		};
		
		
		tsv.end();
	}
}