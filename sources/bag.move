module package_addr::bag {
  use sui::bag::{Self, Bag};
	
	public struct GameInventory {
		items: Bag,
	}
	public fun new(ctx: &mut TxContext): GameInventory {
		GameInventory { items: bag::new(ctx)}
	}
	
	//add a key value pair to GameInventory
	public fun add<K: copy + drop + store, V: store>(bag: &mut GameInventory, k: K, v: V){
		bag::add(&mut bag.items, k, v);
	}
	//remove a key value pair to GameInventory
	public fun remove<K: copy + drop + store, V: store>(bag: &mut GameInventory, k: K): V {
		bag::remove(&mut bag.items, k)
	}
	//borrow a mutable reference to the value associated with the key in GameInventory
	public fun borrow_mut<K: copy + drop + store, V: store>(bag: &mut GameInventory, k: K): &mut V {
		bag::borrow_mut(&mut bag.items, k)
	}
	//Check if a value associated with the key exists in the GameInventory
	public fun contains<K: copy + drop + store>(bag: &GameInventory, k: K): bool {
		bag::contains<K>(&bag.items, k)
	}
	//Returns the size of the GameInventory, the number of the key-value pairs
	public fun length(bag: &GameInventory): u64 {
		bag::length(&bag.items)
	}

}
