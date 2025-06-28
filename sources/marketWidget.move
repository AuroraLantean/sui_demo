module package_addr::Widget {
	
	public struct Widget has key, store {
		id: UID,
	}
	
	public entry fun mint(ctx: &mut TxContext){
		let obj = Widget {
			id: object::new(ctx)
		};
		transfer::transfer(obj, ctx.sender());
	}
}