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
	public fun magic(sword: &Sword): u64 {
		sword.magic
	}
	public fun strength(sword: &Sword): u64 {
		sword.strength
	}
	public fun sword_made(sword: &Forge): u64 {
		sword.sword_made
	}
	public entry fun make_sword(magic: u64, strength: u64, recipient: address, ctx: &mut TxContext){
		let sword = Sword {
			id: object::new(ctx),
			magic, strength
		};
		transfer::transfer(sword, recipient);
	}
	public entry fun update_magic(sword: &mut Sword, magic: u64){
		sword.magic = magic;
	}
	public entry fun delete_sword(sword: Sword){
		let Sword {
			id,
			magic: _,
			strength: _,
		} = sword;
		id.delete();
	}

	//sui move test sword -s
	#[test]
	public fun test_make_sword() {
		let ctx = tx_context::dummy();
		let mut ctxm = ctx;
		let sword = Sword {
			id: object::new( &mut ctxm),
			//owner: ctxm.sender(),
			magic: 37,
			strength: 5,
		};
		assert!(magic(&sword) == 37 && strength(&sword) == 5, 1);
		let dummy2 = @0xCAFE;
		transfer::transfer(sword,dummy2);
	}

	#[test]
	public fun test_sword2() {
		use sui::test_scenario as ts;
		let admin: address = @0xA00;
		let user1: address = @0x001;
		let user2: address = @0x002;
		
    let mut scenario_val = ts::begin(admin);
    let sn = &mut scenario_val;
		{
			init(ts::ctx(sn));
		};
		
		//make sword
		ts::next_tx(sn, admin);
		{
			make_sword(37, 5, user1, ts::ctx(sn));
		};
		
		// transfer the sword from user1 to user2
		ts::next_tx(sn, user1);
		{
			let sword = ts::take_from_sender<Sword>(sn);
			transfer::transfer(sword,user2);
		};
		
		//update the sword
		ts::next_tx(sn, user2);
		{
			let mut sword = ts::take_from_sender<Sword>(sn);
			update_magic(&mut sword, 38);
			ts::return_to_sender(sn, sword);
		};
		
		//check the sword
		ts::next_tx(sn, user2);
		{
			let sword = ts::take_from_sender<Sword>(sn);
			assert!(magic(&sword) == 38, 1);
			assert!(strength(&sword) == 5, 1);
			ts::return_to_sender(sn, sword);
		};

		//delete the sword
		ts::next_tx(sn, user2);
		{
			let sword = ts::take_from_sender<Sword>(sn);
			delete_sword(sword);
		};
		ts::end(scenario_val);
	}
}