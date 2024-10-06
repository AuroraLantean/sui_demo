/*
- anyone can create and share a counter
- everyone can increment a counter by 1
- the owner of the counter can reset it to any value
*/
module publisher::counter {
  /// A shared counter.
  public struct Counter has key {
    id: UID,
    owner: address,
    value: u64
  }

  fun init(ctx: &mut TxContext) {
    transfer::share_object(Counter {
      id: object::new(ctx),
      owner: ctx.sender(),
      value: 0
    })
  }

  /// Increment a counter by 1.
  public fun increment(counter: &mut Counter) {
    counter.value = counter.value + 1;
  }

  /// Set value (only runnable by the Counter owner)
  public fun set_value(counter: &mut Counter, value: u64, ctx: &TxContext) {
    assert!(counter.owner == ctx.sender(), 0);
    counter.value = value;
  }
	
	#[test_only]
	use std::string::{String, utf8};
	use std::debug::print;	
  #[test(user1 = @0x123, user2 = @0x144)]
  fun counter_1(user1: signer) {
		print(&utf8(b"--------== Test"));
		
  }
}
