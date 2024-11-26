/*Any user can make a new game with a list of options, then the user himself(game owner) and other users can bet on one/some/all option(s).

After some time, the game owner can settle the game outcome and withdraw fees.
And users who bet can claim rewards if they win.*/
module package_addr::prediction {
	//use sui::dynamic_field as df;
	use sui::coin::{Self, Coin};
  use sui::balance::Balance;
	//use sui::bag::{Self, Bag};
	use sui::table::{Self, Table};
	use std::string::{utf8, String, append};
	//use sui::balance::{Self, Balance};
	//use 0x1::option::{some, is_some, none, extract};

	public struct UserData has store, copy {
		bets: vector<u64>,
	}
  public struct AdminCap has key {
    id: UID
  }
  fun init(ctx: &mut TxContext) {
		let admin_cap = AdminCap {
				id: object::new(ctx)
		};
		transfer::transfer(admin_cap, ctx.sender())
  }

	public struct Prediction<phantom COIN> has key {
		id: UID,
		owner: address,
		//public_key: vector<u8>,
		balance: Balance<COIN>,
		choices: vector<String>,
		users: Table<address, UserData>,
	}

	const EAmountTooSmall: u64 = 0;
	const EAmountTooBig: u64 = 1;
	const EChoiceInvalid: u64 = 2;
	const EInsufficientGasCoinId: u64 = 2;
	const ENotOwner: u64 = 10;
	
	//make a new shared object: Prediction
	public entry fun init_prediction<COIN>(
		admin_cap: AdminCap,
		gasCoinId: Coin<COIN>,
		owner: address,
		choices: vector<String>, ctx: &mut TxContext) {

		assert!(gasCoinId.value() > 0, EInsufficientGasCoinId);

		let prediction = Prediction {
			id: object::new(ctx),
			owner: owner,//ctx.sender(),
			balance: gasCoinId.into_balance(),
			choices,
			users: table::new<address, UserData>(ctx),
		};
		let AdminCap { id } = admin_cap;
		object::delete(id);
		transfer::share_object(prediction);
	}

	public entry fun bet<COIN>(prediction: &mut Prediction<COIN>, amount: u64, mut gasCoinId: Coin<COIN>, choice: u64, ctx: &mut TxContext) {

		assert!(gasCoinId.value() >= amount , EAmountTooSmall);
		assert!(choice <= 3, EChoiceInvalid);
		let sender = ctx.sender();
		
		let bet_amt = gasCoinId.split(amount, ctx);
		prediction.balance.join(bet_amt.into_balance());

		let isFound = table::contains<address, UserData>(&prediction.users, sender);
		
		if(isFound){
			let user_data = table::borrow_mut<address, UserData>(&mut prediction.users, sender);
			
			let value = vector::borrow_mut(&mut user_data.bets, choice);
			*value = *value + amount;

		} else {
			let mut user_data = UserData {
				bets: vector<u64>[0, 0, 0, 0],
			};
			let value = vector::borrow_mut(&mut user_data.bets, choice);
			*value = *value + amount;
			
			table::add(&mut prediction.users, sender, user_data);
		};
		transfer::public_transfer(gasCoinId, sender);
	}
	
	public fun get_user<COIN>(prediction: &Prediction<COIN>, user: address, index: u64): u64 {
		let isFound = table::contains<address, UserData>(&prediction.users, user);
		
		if(!isFound){
			return 0
		};
		let user_data = table::borrow<address, UserData>(&prediction.users, user);

		let value = vector::borrow(&user_data.bets, index);
		*value
	}
	public fun get_balance<COIN>(prediction: &Prediction<COIN>): u64 {
		prediction.balance.value()
	}
	
	// --------== Admin functions
  public entry fun deposit<COIN>(prediction: &mut Prediction<COIN>, amount: u64, mut gasCoinId: Coin<COIN>, ctx: &mut TxContext) {
		assert!(ctx.sender() == prediction.owner, ENotOwner);
		assert!(gasCoinId.value() >= amount , EAmountTooSmall);
		let amt = gasCoinId.split(amount, ctx);
		prediction.balance.join(amt.into_balance());
		transfer::public_transfer(gasCoinId, ctx.sender());
	}
	
  public entry fun withdraw<COIN>(prediction: &mut Prediction<COIN>, amount: u64, ctx: &mut TxContext) {
		assert!(ctx.sender() == prediction.owner, ENotOwner);
		assert!(amount <= get_balance(prediction), EAmountTooBig);
		let coin = coin::take(&mut prediction.balance, amount, ctx);
		transfer::public_transfer(coin, prediction.owner);
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
  #[test_only]
  public fun transfer_admin_cap(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
			id: object::new(ctx)
    };
    transfer::transfer(admin_cap, ctx.sender());
  }
	
	#[test]
	fun test_init_prediction() {
		let admin: address = @0xA;
		let owner: address = @0xF;
		let user1: address = @0x001;
		let user2: address = @0x002;
		let user3: address = @0x003;
		let mint_amt: u64 = 1000;

		let mut tsv = ts::begin(admin);
		prt(&utf8(b"------== deploy & init"));
		{
			transfer_admin_cap(tsv.ctx());

			tsv.next_tx(admin);
			let choices = vector<String>[utf8(b"Bitcoin"), utf8(b"Ethereum"), utf8(b"Solana"), utf8(b"Sui")];
			let coin1 = mint(&mut tsv, mint_amt);

			let admin_cap = ts::take_from_sender<AdminCap>(&tsv);
			init_prediction<SUI>(admin_cap, coin1, owner, choices, tsv.ctx());
		};

	prt(&utf8(b"------== read_init_prediction"));
		{
			tsv.next_tx(admin);
			let prediction: Prediction<SUI> = tsv.take_shared();//prt(&prediction);
			assert!(prediction.owner == owner);
			assert!(prediction.choices[0] == utf8(b"Bitcoin"));
			assert!(prediction.choices[3] == utf8(b"Sui"));
			ts::return_shared(prediction);
		};

		let bet_amt1: u64 = 123;
		let user1_choice: u64 = 0;
		prt(&utf8(b"------== user1: bet"));
		{
			tsv.next_tx(user1);
			let mut prediction: Prediction<SUI> = tsv.take_shared();
			let coin1 = mint(&mut tsv, mint_amt);

			prt(&utf8(b"User1 has balance:"));
			prt(&value(&coin1));
			//prt(&append(&mut utf8(b"User1 has balance:"),vector[value(&coin1)]));
			assert!(value(&coin1) == mint_amt, 1);
		
			//invoke bet()
			bet<SUI>(&mut prediction, bet_amt1, coin1, user1_choice, tsv.ctx());

			ts::return_shared(prediction);
		};

		prt(&utf8(b"------== user1 balance"));
		{
			tsv.next_tx(user2);
			let coin1b: Coin<SUI> = ts::take_from_address<Coin<SUI>>(&tsv, user1);//ts::take_from_sender<Coin<SUI>>(&mut tsv);
			assert!(coin1b.value()== mint_amt-bet_amt1, 0);
			ts::return_to_address(user1, coin1b);
		};

		prt(&utf8(b"------== user1: check"));
		{
			tsv.next_tx(user2);
			let prediction: Prediction<SUI> = tsv.take_shared();
			prt(&prediction);

			let amount = get_user<SUI>(&prediction, user1, user1_choice);
			prt(&utf8(b"User1 has bet:"));
			prt(&amount);
			assert!(amount == bet_amt1);
			assert!(&prediction.balance.value() == bet_amt1+mint_amt);
			ts::return_shared(prediction);
		};
		
		prt(&utf8(b"------== user1: bet again"));
		{
			tsv.next_tx(user1);
			let mut prediction: Prediction<SUI> = tsv.take_shared();

			let coin1 = mint(&mut tsv, mint_amt);
			/*prt(&utf8(b"User1 has balance:"));
			prt(&value(&coin1));
			assert!(value(&coin1) == (mint_amt-bet_amt1), 1);*/
		
			//invoke bet()
			bet<SUI>(&mut prediction, bet_amt1, coin1, user1_choice, tsv.ctx());
			//coin1.burn_for_testing();
			ts::return_shared(prediction);
		};

		prt(&utf8(b"------== user1: check again"));
		{
			tsv.next_tx(user2);
			let prediction: Prediction<SUI> = tsv.take_shared();
			prt(&prediction);

			let amount = get_user<SUI>(&prediction, user1, user1_choice);
			prt(&utf8(b"User1 has bet:"));
			prt(&amount);
			assert!(amount == bet_amt1*2);
			assert!(&prediction.balance.value() == bet_amt1*2+mint_amt);
			ts::return_shared(prediction);
		};

prt(&utf8(b"------== Owner: withdraw"));
		{
			tsv.next_tx(owner);
			let mut prediction: Prediction<SUI> = tsv.take_shared();
			
			let amount = bet_amt1 * 2;
			withdraw<SUI>(&mut prediction, amount, tsv.ctx());
			
			tsv.next_tx(user2);
			prt(&utf8(b"Prediction balance:"));
			prt(&prediction.balance.value());
			assert!(&prediction.balance.value() == mint_amt);
			ts::return_shared(prediction);
		};
		//coin1.burn_for_testing();
		tsv.end();
	}
/*prt(&utf8(b"------== user3: withdraw"));
		{
			tsv.next_tx(user3);
			let mut prediction: Prediction<SUI> = tsv.take_shared();
			
			let amount = bet_amt1;
			withdraw<SUI>(&mut prediction, amount, tsv.ctx());
			ts::return_shared(prediction);
		};
		*/
}