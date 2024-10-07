module packagename::staking {
	use std::string::{utf8, String};
	
	public struct STAKING has drop {}
	public struct User has key {
		id: UID,
		name: String,
		staked_balc: u64,
	}

	fun init(_witnes: STAKING, ctx: &mut TxContext) {
		let object = User {
			id: object::new(ctx),
			name: utf8(b"John"),
			staked_balc: 0,
		};
		transfer::share_object(object)
	}
}