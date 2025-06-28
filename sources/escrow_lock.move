// https://docs.sui.io/guides/developer/app-examples/trustless-swap

/*Object owner locks an object with a single-use `keyObj`, 
When the object owner is paid, he should supply the keyObj 

To tamper with the object would require unlocking it, which consumes the keyObj. Consequently, there would no longer be a keyObj to finish the trade.
*/
module package_addr::escrow_lock {
	use sui::{ event, 
		dynamic_object_field::{Self as dof},
	};

	// === Error codes ===
	const ELockKeyMismatch: u64 = 0;

	/// The DOF field name that holds Locker objects
	public struct DofFieldName has copy, store, drop {}

	/// A wrapper that prevents access/modification to `obj` by requiring access to a `KeyObj`.
	/// Object is added as a Dynamic Object Field so that it can still be looked-up.
	public struct Locker<phantom T: key + store> has key, store {
		id: UID,
		keyObjId: ID,
	}

	/// KeyObj to open a locker object (consuming the `KeyObj`)
	public struct KeyObj has key, store { id: UID }

	// === Public Functions ===
	/// Lock `obj` and get a key_obj that can be used to unlock it.
	public fun lock<T: key + store>(
		obj: T,
		ctx: &mut TxContext,
	): (Locker<T>, KeyObj) {
		
		let key_obj = KeyObj { id: object::new(ctx) };
		let mut locker = Locker {
			id: object::new(ctx),
			keyObjId: object::id(&key_obj),
		};

		event::emit(NewLockEvent {
			lock_id: object::id(&locker),
			key_id: object::id(&key_obj),
			creator: ctx.sender(),
			item_id: object::id(&obj)
		});

		// Adds the `object` as a DOF for the `locker` object
		dof::add(&mut locker.id, DofFieldName {}, obj);

		(locker, key_obj)
	}

	/// Unlock the object in `locker`, consuming the `key_obj`.  Fails if the wrong
	public fun unlock<T: key + store>(mut locker: Locker<T>, key_obj: KeyObj): T {
		
		assert!(locker.keyObjId == object::id(&key_obj), ELockKeyMismatch);
		let KeyObj { id } = key_obj;
		id.delete();

		let obj = dof::remove<DofFieldName, T>(&mut locker.id, DofFieldName {});

		event::emit(LockDestroyedEvent { lock_id: object::id(&locker) });

		let Locker { id, keyObjId: _ } = locker;
		id.delete();
		obj
	}

	// === Events ===
	public struct NewLockEvent has copy, drop {
		/// The ID of the `Locker` object.
		lock_id: ID,
		/// The ID of the keyObjId that unlocks a locker object in a `Locker`.
		key_id: ID,
		/// The creator of the locker object.
		creator: address,
		/// The ID of the item that is locker.
		item_id: ID,
	}

	public struct LockDestroyedEvent has copy, drop {
		/// The ID of the `Locker` object.
		lock_id: ID
	}

	// === Tests ===
	#[test_only] use sui::coin::{Self, Coin};
	#[test_only] use sui::sui::SUI;
  #[test_only] use sui::test_scenario::{begin, Scenario};

	#[test_only]
	fun test_coin(ts: &mut Scenario): Coin<SUI> {
		coin::mint_for_testing<SUI>(42, ts.ctx())
	}

	#[test]
	fun test_lock_unlock() {
		let mut ts = begin(@0xA);
		let coin = test_coin(&mut ts);

		let (locker, keyObjId) = lock(coin, ts.ctx());
		let coin = locker.unlock(keyObjId);

		coin.burn_for_testing();
		ts.end();
	}

	#[test]
	#[expected_failure(abort_code = ELockKeyMismatch)]
	fun test_lock_key_mismatch() {
		let mut ts = begin(@0xA);
		let coin = test_coin(&mut ts);
		let another_coin = test_coin(&mut ts);
		let (l, _k) = lock(coin, ts.ctx());
		let (_l, k) = lock(another_coin, ts.ctx());

		let _key = l.unlock(k);
		abort 1337
	}
}
