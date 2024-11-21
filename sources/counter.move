/* https://docs.sui.io/guides/developer/app-examples/e2e-counter
- anyone can make and share a counter
- everyone can increment a counter by 1
- the owner of the counter can reset it to any value
*/
//module package_name::module_name {}
module package_addr::counter {
  public struct Counter has key {
    id: UID,
    owner: address,
    value: u64
  }

  fun init(ctx: &mut TxContext) {
    transfer::share_object(Counter {
      id: object::new(ctx),
      owner: ctx.sender(),
			//owner: tx_context::sender(ctx),
      value: 0
    })
  }
	public fun owner(counter: &Counter): address {
      counter.owner
  }

  public fun value(counter: &Counter): u64 {
      counter.value
  }
  public fun make_user_counter(ctx: &mut TxContext) {
      transfer::share_object(Counter {
          id: object::new(ctx),
          owner: tx_context::sender(ctx),
          value: 0
      })
  }
  public fun delete_counter(counter: Counter, ctx: &TxContext) {
      assert!(counter.owner == ctx.sender(), 0);
      let Counter {id, owner:_, value:_} = counter;
      id.delete();
  }
		
  public fun increment(counter: &mut Counter, added_value: u64) {
    counter.value = counter.value + added_value;
  }

  /// only runnable by the Counter owner)
  public fun set_value(counter: &mut Counter, value: u64, ctx: &TxContext) {
    assert!(counter.owner == ctx.sender(), 0);
    counter.value = value;
  }
	
	/*#[test_only]
	use std::string::{String, utf8};
	use std::debug::print;	
  #[test(user1 = @0x123, user2 = @0x144)]
  fun counter_1(user1: signer) {
		print(&utf8(b"--------== Test"));
  }*/
}

//sui move test counter -s
#[test_only]
module package_addr::counter_test {
	use sui::test_scenario as ts;
	use package_addr::counter::{Self, Counter};

	#[test]
	fun counter_1() {
		let owner = @0xC0FFEE;
		let user1 = @0xA1;

		let mut ts = ts::begin(user1);
		// make counter
		{
				ts.next_tx(owner);
				counter::make_user_counter(ts.ctx());
		};

		// read counter
		{
			ts.next_tx(user1);
			let mut counter: Counter = ts.take_shared();

			assert!(counter.owner() == owner);
			assert!(counter.value() == 0);
			counter.increment(1);
			counter.increment(2);
			counter.increment(3);
			ts::return_shared(counter);
		};

		// update counter
		{
			ts.next_tx(owner);
			let mut counter: Counter = ts.take_shared();

			assert!(counter.owner() == owner);
			assert!(counter.value() == 6);

			counter.set_value(100, ts.ctx());
			ts::return_shared(counter);
		};

		{
			ts.next_tx(user1);
			let mut counter: Counter = ts.take_shared();

			assert!(counter.owner() == owner);
			assert!(counter.value() == 100);

			counter.increment(7);
			assert!(counter.value() == 107);
			ts::return_shared(counter);
		};

		// delete counter
		{
			ts.next_tx(owner);
			let counter: Counter = ts.take_shared();
			counter.delete_counter(ts.ctx());
		};
		ts.end();
	}
}