/*Any user can make a new game with a list of options, then the user himself(game owner) and other users can bet on one/some/all option(s).

After some time, the game owner can settle the game outcome and withdraw fees.
And users who bet can claim rewards if they win.
*/
module package_addr::prediction;
use std::string::{String};//utf8, append
use sui::{coin::{Self, Coin}, balance::Balance, table::{Self, Table}};
//use sui::dynamic_field as df;
//use sui::bag::{Self, Bag};
//use 0x1::option::{some, is_some, none, extract};

	public struct UserData has store, copy {
		bets: vector<u64>,
	}
  public struct AdminCap has key {
    id: UID
  }
  //runs at publication time
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
  // Owner Object
  public struct OwnerCap has key { 
    id: UID,
    pred_id_rb: ID, 
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

		let pred_id = object::new(ctx);
		let pred_id_rb: ID = object::uid_to_inner(&pred_id);
    // send the Owner Object
    transfer::transfer(OwnerCap {
      id: object::new(ctx),
      pred_id_rb,
    }, owner);//tx_context::sender(ctx)

		let prediction = Prediction {
			id: pred_id,
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
	
  public entry fun withdraw<COIN>(prediction: &mut Prediction<COIN>, owner_cap: &OwnerCap, amount: u64, ctx: &mut TxContext) {

		assert!(&owner_cap.pred_id_rb == object::uid_as_inner(&prediction.id), ENotOwner);
		//assert!(ctx.sender() == prediction.owner, ENotOwner);
		assert!(amount <= get_balance(prediction), EAmountTooBig);
		let coin = coin::take(&mut prediction.balance, amount, ctx);
		transfer::public_transfer(coin, prediction.owner);
  }
	
	// === Tests ===
	#[test_only] use sui::sui::SUI;
	#[test_only] use sui::coin::value;
  #[test_only] use sui::test_scenario::{begin, return_shared, return_to_sender, take_from_address, return_to_address, Scenario};
	#[test_only] use std::debug::print;
	#[test_only] use std::string::utf8;
			
	#[test_only]
	fun mint_sui(sn: &mut Scenario, amount: u64): Coin<SUI> {
		coin::mint_for_testing<SUI>(amount, sn.ctx())
	}
  #[test_only]
  public fun transfer_admin_cap(ctx: &mut TxContext) {
    let admin_cap = AdminCap {
			id: object::new(ctx)
    };
    transfer::transfer(admin_cap, ctx.sender());
  }
  #[test_only]
  public fun pp(bytes: vector<u8>) {
    print(&utf8(bytes));
  }
	#[test]
	fun test_init_prediction() {
		let admin: address = @0xA;
		let owner: address = @0xF;
		let user1: address = @0x01;
		let user2: address = @0x02;
		let _user3: address = @0x03;
		let mint_amt: u64 = 1000;

		let mut sce = begin(admin);
		pp(b"------== deploy & init");
		{
			transfer_admin_cap(sce.ctx());

			sce.next_tx(admin);
			let choices = vector<String>[utf8(b"Bitcoin"), utf8(b"Ethereum"), utf8(b"Solana"), utf8(b"Sui")];
      
			let coin1 = mint_sui(&mut sce, mint_amt);

			let admin_cap = sce.take_from_sender<AdminCap>();
			init_prediction<SUI>(admin_cap, coin1, owner, choices, sce.ctx());
		};

	pp(b"------== read_init_prediction");
		{
			sce.next_tx(admin);
			let prediction: Prediction<SUI> = sce.take_shared();//pp(&prediction);
			assert!(prediction.owner == owner);
			assert!(prediction.choices[0] == utf8(b"Bitcoin"));
			assert!(prediction.choices[3] == utf8(b"Sui"));
			return_shared(prediction);
		};

		let bet_amt1: u64 = 123;
		let user1_choice: u64 = 0;
		pp(b"------== user1: bet");
		{
			sce.next_tx(user1);
			let mut prediction: Prediction<SUI> = sce.take_shared();
			let coin1 = mint_sui(&mut sce, mint_amt);

			pp(b"User1 has balance:");
			print(&value(&coin1));
			//pp(&append(&mut utf8(b"User1 has balance:"),vector[value(&coin1)]));
			assert!(value(&coin1) == mint_amt, 1);
		
			//invoke bet()
			bet<SUI>(&mut prediction, bet_amt1, coin1, user1_choice, sce.ctx());

			return_shared(prediction);
		};

		pp(b"------== user1 balance");
		{
			sce.next_tx(user2);
			let coin1b: Coin<SUI> = take_from_address<Coin<SUI>>(&sce, user1);
			assert!(coin1b.value()== mint_amt-bet_amt1, 0);
			return_to_address(user1, coin1b);
		};

		pp(b"------== user1: check");
		{
			sce.next_tx(user2);
			let prediction: Prediction<SUI> = sce.take_shared();
			print(&prediction);

			let amount = get_user<SUI>(&prediction, user1, user1_choice);
			pp(b"User1 has bet:");
			print(&amount);
			assert!(amount == bet_amt1);
			assert!(&prediction.balance.value() == bet_amt1+mint_amt);
			return_shared(prediction);
		};
		
		pp(b"------== user1: bet again");
		{
			sce.next_tx(user1);
			let mut prediction: Prediction<SUI> = sce.take_shared();

			let coin1 = mint_sui(&mut sce, mint_amt);
			/*pp(b"User1 has balance:"));
			pp(&value(&coin1));
			assert!(value(&coin1) == (mint_amt-bet_amt1), 1);*/
		
			//invoke bet()
			bet<SUI>(&mut prediction, bet_amt1, coin1, user1_choice, sce.ctx());
			//coin1.burn_for_testing();
			return_shared(prediction);
		};

		pp(b"------== user1: check again");
		{
			sce.next_tx(user2);
			let prediction: Prediction<SUI> = sce.take_shared();
			print(&prediction);

			let amount = get_user<SUI>(&prediction, user1, user1_choice);
			pp(b"User1 has bet:");
			print(&amount);
			assert!(amount == bet_amt1*2);
			assert!(&prediction.balance.value() == bet_amt1*2+mint_amt);
			return_shared(prediction);
		};

pp(b"------== Owner: withdraw");
		{
			sce.next_tx(owner);
			let mut prediction: Prediction<SUI> = sce.take_shared();
			let owner_cap = sce.take_from_sender<OwnerCap>();
			
			let amount = bet_amt1 * 2;
			withdraw<SUI>(&mut prediction, &owner_cap, amount, sce.ctx());
			sce.return_to_sender(owner_cap);
			
			sce.next_tx(user2);
			pp(b"Prediction balance:");
			print(&prediction.balance.value());
			assert!(&prediction.balance.value() == mint_amt);
			return_shared(prediction);
		};
		//coin1.burn_for_testing();
		sce.end();
	}
/*pp(b"------== user3: withdraw"));
		{
			sce.next_tx(user3);
			let mut prediction: Prediction<SUI> = sce.take_shared();
			
			let amount = bet_amt1;
			withdraw<SUI>(&mut prediction, amount, sce.ctx());
			return_shared(prediction);
		};
		*/
