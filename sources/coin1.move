module package_addr::my_coin;
//https://docs.sui.io/guides/developer/coin
use sui::coin::{Self, Coin, TreasuryCap};

public struct MY_COIN has drop {}
//const TOTAL_SUPPLY: u64 = 1_000_000_000_000_000_000;//includes decimal zeros
const INITIAL_SUPPLY: u64 = 900_000_000_000_000_000;
//const REMAINING: u64 = 100_000_000_000_000_000;

fun init(witness: MY_COIN, ctx: &mut TxContext) {
		let (mut treasury, metadata) = coin::create_currency(
				witness,
				9,
				b"MY_COIN",
				b"",
				b"",
				option::none(),
				ctx,
		);
    mint( &mut treasury, INITIAL_SUPPLY, ctx.sender(), ctx);
		transfer::public_freeze_object(metadata);
		transfer::public_transfer(treasury, ctx.sender())
}

public fun mint(
		treasury_cap: &mut TreasuryCap<MY_COIN>,
		amount: u64,
		recipient: address,
		ctx: &mut TxContext,
) {
		let coin = coin::mint(treasury_cap, amount, ctx);
		transfer::public_transfer(coin, recipient)
}

//----------== Test
#[test_only] use sui::test_scenario::{begin};
#[test_only] use sui::coin::value;
#[test_only] use std::debug::print as pp;
#[test_only] use std::string::{utf8};

#[test]
fun test_init() {
let admin = @0xAd;
let _bob = @0xb0;
let mut sce = begin(admin);
{
    let otw = MY_COIN{};
    init(otw, sce.ctx());
};

sce.next_tx(admin);
{
  let coin = sce.take_from_sender<Coin<MY_COIN>>();
  pp(&utf8(b"admin balc1"));
  pp(&value(&coin));
  assert!(value(&coin) == INITIAL_SUPPLY, 441);
  sce.return_to_sender(coin);
};

//mint 2nd time
sce.next_tx(admin);
{
  let mut treasury = sce.take_from_sender<TreasuryCap<MY_COIN>>();
      mint(
        &mut treasury,
        2000,
        admin,//sce.ctx().sender(),
        sce.ctx()
    );
  sce.return_to_sender(treasury);
};

sce.next_tx(admin);
{
  let coin = sce.take_from_sender<Coin<MY_COIN>>();
  pp(&utf8(b"admin balc2"));
  pp(&value(&coin));
  //assert!(value(&coin) == INITIAL_SUPPLY+2000, 442);
  sce.return_to_sender(coin);
};
sce.end();
}
/*
//mint 3rd time
sce.next_tx(admin);
{
  let mut treasury = sce.take_from_sender<TreasuryCap<MY_COIN>>();
      mint(
        &mut treasury,
        3000,
        admin,//sce.ctx().sender(),
        sce.ctx()
    );
  sce.return_to_sender(treasury);
};

sce.next_tx(admin);
{
  let coin = sce.take_from_sender<Coin<MY_COIN>>();
  pp(&utf8(b"admin balc3"));
  pp(&value(&coin));
  //assert!(value(&coin) == INITIAL_SUPPLY+1000, 442);
  sce.return_to_sender(coin);
};
*/