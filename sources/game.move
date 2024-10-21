module package_addr::game {
	
  public struct Sword has key, store {
    id: UID,
    magic: u64,
    strength: u64,
  }
	public struct Forge has key, store {
		id: UID,
		sword_made: u64,
	}
	
	fun init(ctx: &mut TxContext) {
		let admin = Forge {
			id: object::new(ctx),
			sword_made: 0,
		};
		transfer::transfer(admin, tx_context::sender(ctx));
	}
	public fun magic(self: &Sword): u64 {
		self.magic
	}
	public fun strength(self: &Sword): u64 {
		self.strength
	}
	public fun sword_made(self: &Forge): u64 {
		self.sword_made
	}
	public entry fun make_sword(magic: u64, strength: u64, recipient: address, ctx: &mut TxContext){
		let sword = Sword {
			id: object::new(ctx),
			magic, strength
		};
		transfer::transfer(sword, recipient);
	}

	//sui move test sword -s
	#[test]
	public fun test_make_sword() {
		let ctx = tx_context::dummy();
		let mut ctxm = ctx;
		let sword = Sword {
			id: object::new( &mut ctxm),
			magic: 37,
			strength: 5,
		};
		assert!(magic(&sword) == 37 && strength(&sword) == 5, 1);
		let dummy2 = @0xCAFE;
		transfer::transfer(sword,dummy2);
	}

	#[test]
	public fun test_sword2() {
		use sui::test_scenario;
		let admin: address = @0xA00;
		let user1: address = @0x001;
		let user2: address = @0x002;
		
    let mut scenario_val = test_scenario::begin(admin);
    let scenario = &mut scenario_val;
		{
			init(test_scenario::ctx(scenario));
		};
		test_scenario::next_tx(scenario, admin);
		{
			make_sword(37, 5, user1, test_scenario::ctx(scenario));
		};
		test_scenario::next_tx(scenario, user1);
		{
			let sword = test_scenario::take_from_sender<Sword>(scenario);
			transfer::transfer(sword,user2);
		};
		test_scenario::next_tx(scenario, user2);
		{
			let sword = test_scenario::take_from_sender<Sword>(scenario);
			assert!(magic(&sword) == 37 && strength(&sword) == 5, 1);
			test_scenario::return_to_sender(scenario, sword);
		};
		test_scenario::end(scenario_val);
	}
}