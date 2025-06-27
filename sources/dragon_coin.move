// from the Sui Move by Example book 
// (https://examples.sui.io/samples/coin.html)
// docs: https://github.com/MystenLabs/sui/tree/main/crates/sui-framework/docs/sui
module package_addr::dragon;
    
use sui::coin::{Self, Coin, TreasuryCap, CoinMetadata};
use sui::balance::{Balance};
use sui::clock::{Clock};
use sui::url::{Self, Url};
use std::string::String;
use std::ascii;
// Coin type = Coin<package_object::dragoncoin::DRAGON
    
const EInvalidAmount: u64 = 0;
const ESupplyExceeded: u64 = 1;
const ETokenLocked: u64 = 2;

/// Make sure that the name of the type matches the module's name.
public struct DRAGON has drop {}

#[test_only]
public fun new_otw(_ctx: &mut TxContext): DRAGON {
  DRAGON {}
}

public struct MintCapability has key {
    id: UID,
    treasury: TreasuryCap<DRAGON>,
    total_minted: u64,
}
public struct Locker has key, store {
    id: UID,
    unlock_date: u64,
    balance: Balance<DRAGON>,
}

const TOTAL_SUPPLY: u64 = 1_000_000_000_000_000_000;//includes decimal zeros
const INITIAL_SUPPLY: u64 = 900_000_000_000_000_000;
const REMAINING: u64 = 
100_000_000_000_000_000;
//const COMMUNITY_SUPPLY: u64 = 700_000_000_000_000_000;

// https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/sui/coin.md#function-create_currency
fun init( otw: DRAGON, ctx: &mut TxContext) {
    let (treasury, metadata) = coin::create_currency(
        otw, 
        9, 
        b"DRAG", 
        b"Dragon coin", 
        b"Dragon coin is the one coin to rule them all", option::some<Url>(url::new_unsafe_from_bytes(b"https://dukudama.sirv.com/Images/dragonGold001-512x512.png"),), 
        ctx
    );//b"data:image/jpeg;base64,DATA"  ... DATA is from $ base64 -i your_image.jpg | pbcopy
    
    let mut mint_cap = MintCapability {
      id: object::new(ctx),
      treasury,
      total_minted: 0,
    };
    mint( &mut mint_cap, INITIAL_SUPPLY, ctx.sender(), ctx);
    //mint(&mut treasury, COMMUNITY_SUPPLY, @community_wallet, ctx);

    //Optioin::none()
    transfer::public_freeze_object(metadata);
    //transfer::public_transfer(metadata, tx_context::sender(ctx));
    
    //transfer::public_transfer(treasury, ctx.sender());
    transfer::transfer(mint_cap, ctx.sender());
}

#[test_only]
public fun new( otw: DRAGON, ctx: &mut TxContext) {
  init( otw, ctx);
}

// https://github.com/MystenLabs/sui/blob/main/crates/sui-framework/docs/sui/coin.md#sui_coin_mint
public fun mint(
    //treasury_cap: &mut TreasuryCap<DRAGON>,
    mint_cap: &mut MintCapability,
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    let coin = mint_internal( mint_cap, amount, ctx);
    pp(&utf8(b"mint()"));
    pp(&recipient);
    pp(&value(&coin));
    transfer::public_transfer(coin, recipient);
}
fun mint_internal
(
    mint_cap: &mut MintCapability,
    amount: u64, 
    //recipient: address,
    ctx: &mut TxContext
): Coin<DRAGON> 
{
    assert!(amount > 0, EInvalidAmount);
    assert!(mint_cap.total_minted + amount <= TOTAL_SUPPLY, ESupplyExceeded);
    
    let treasury = &mut mint_cap.treasury;
    let coin = coin::mint(treasury, amount, ctx);

    //transfer::public_transfer(new_coin, recipient);
    //coin::mint_and_transfer(cap, amount, recipient, ctx);
    mint_cap.total_minted = mint_cap.total_minted + amount;
    coin
}

public fun mint_locked(
    mint_cap: &mut MintCapability,
    amount: u64,
    recipient: address,
    duration: u64,//in milisec
    clock: &Clock,
    ctx: &mut TxContext
) {
    let coin = mint_internal( mint_cap, amount, ctx);

    let start_date = clock.timestamp_ms();
    let unlock_date = start_date + duration;

    let locker = Locker {
        id: object::new(ctx),
        unlock_date,
        balance: coin::into_balance(coin)
    };
    transfer::public_transfer(locker, recipient);
}

//pass locker without reference because we will destroy it
entry fun withdraw_locked(locker: Locker, clock: &Clock, ctx: &mut TxContext): u64 {
    let Locker { id, mut balance, unlock_date} = locker;
    assert!(clock.timestamp_ms() >= unlock_date, ETokenLocked);

    let locked_balance_value = balance.value();

    transfer::public_transfer(
        coin::take(&mut balance, locked_balance_value, ctx),
        ctx.sender()
    );
    //balance.withdraw_all();
    balance.destroy_zero();
    object::delete(id);
    locked_balance_value
}

public entry fun burn
(
    mint_cap: &mut MintCapability,
    coin: Coin<DRAGON>
): u64
{
    let treasury = &mut mint_cap.treasury;
    coin::burn(treasury, coin)
}

public fun join(coin1: &mut Coin<DRAGON>, coin2: Coin<DRAGON>): &mut Coin<DRAGON> {
    coin::join( coin1, coin2);
    coin1
}

public fun split(coin: &mut Coin<DRAGON>, amount: u64, ctx: &mut TxContext): Coin<DRAGON> {
    coin::split(coin, amount, ctx)
}

public fun get_total_supply(mint_cap: &mut MintCapability,): u64 {
  let treasury = &mint_cap.treasury;
  coin::total_supply(treasury)
}
public fun get_decimals_coin(metadata: & CoinMetadata<DRAGON>): u8 {
  coin::get_decimals(metadata)
}
public fun get_name_coin(metadata: & CoinMetadata<DRAGON>): String {
  coin::get_name(metadata)
}
public fun get_symbol_coin(metadata: & CoinMetadata<DRAGON>): ascii::String {
  coin::get_symbol(metadata)
}
public fun get_description_coin(metadata: & CoinMetadata<DRAGON>): String {
  coin::get_description(metadata)
}
public fun get_icon_url_coin(metadata: & CoinMetadata<DRAGON>): Option<sui::url::Url> {
  coin::get_icon_url(metadata)
}

public fun update_description_coin(mint_cap: &mut MintCapability, metadata: &mut CoinMetadata<DRAGON>, description_new: String) {
  let treasury = &mint_cap.treasury;
  coin::update_description(treasury, metadata, description_new)
}

// === Tests ===
#[test_only] use sui::test_scenario;
#[test_only] use sui::clock;
#[test_only] use sui::coin::value;
#[test_only] use std::string::{utf8};
#[test_only] use std::debug::print as pp;

#[test]
fun test_init() {
let admin = @0xAd;
let _bob = @0xb0;
let mut sce = test_scenario::begin(admin);
{
    let otw = DRAGON{};
    init(otw, sce.ctx());
};

sce.next_tx(admin);
{
    let mut mint_cap = sce.take_from_sender<MintCapability>();

    let coin = sce.take_from_sender<Coin<DRAGON>>();
    pp(&utf8(b"admin balc:"));
    pp(&value(&coin));
    
    assert!(mint_cap.total_minted == INITIAL_SUPPLY, EInvalidAmount);
    assert!(value(&coin) == INITIAL_SUPPLY, EInvalidAmount);// coin.balance().value()

    let total_supply = get_total_supply(&mut mint_cap);
    pp(&utf8(b"total_supply1"));
    pp(&total_supply);
    assert!(total_supply == INITIAL_SUPPLY, 111);
    sce.return_to_sender(coin);
    sce.return_to_sender(mint_cap);
};

sce.next_tx(admin);
{
    let mut mint_cap = sce.take_from_sender<MintCapability>();
    let sender = sce.ctx().sender();
    pp(&utf8(b"mint sender"));
    pp(&sender);
    mint(
        &mut mint_cap,
        REMAINING,
        admin,//sce.ctx().sender(),
        sce.ctx()
    );//900000000 000000000
    //let mut treasury = sce.take_from_sender<TreasuryCap<DRAGON>>();

    assert!(mint_cap.total_minted == TOTAL_SUPPLY, EInvalidAmount);
    let total_supply = get_total_supply(&mut mint_cap);
    pp(&utf8(b"total_supply2"));
    pp(&total_supply);
    assert!(total_supply == TOTAL_SUPPLY, 111);
    
    let coin = sce.take_from_sender<Coin<DRAGON>>();
    pp(&utf8(b"admin balc1"));
    pp(&value(&coin));
    //assert!(value(&coin) == TOTAL_SUPPLY, 441); // TODO: repeated minting does not add amounts in tests
    
    sce.return_to_sender(coin);
    sce.return_to_sender(mint_cap);
};

// sce.next_tx(bob);
// {
//   let coin = sce.take_from_sender<Coin<DRAGON>>();
//   pp(&utf8(b"bob balc"));
//   pp(&value(&coin));
//   assert!(value(&coin) == REMAINING, 442);
//   sce.return_to_sender(coin);
// };

sce.next_tx(admin);
{
  let sender = sce.ctx().sender();
  pp(&utf8(b"sender"));
  pp(&sender);
  let coin = sce.take_from_sender<Coin<DRAGON>>();
  pp(&utf8(b"admin balc2"));
  pp(&value(&coin));
  pp(&coin.balance().value());
  //assert!(coin.balance().value() == TOTAL_SUPPLY, 442);// TODO: repeated minting does not add amounts in tests
  //assert!(value(&coin) == TOTAL_SUPPLY, 442);
  sce.return_to_sender(coin);
  //let mut mint_cap = sce.take_from_sender<MintCapability>();
  //burn(&mut mint_cap, coin);
  //sce.return_to_sender(mint_cap);
};

sce.next_tx(admin);
{
  let metadata = sce.take_immutable<CoinMetadata<DRAGON>>();
  let decimals = get_decimals_coin(&metadata);
  pp(&decimals);
  assert!(decimals == 9, 1);

  let name = get_name_coin(&metadata);
  pp(&name);
  assert!(name == utf8(b"Dragon coin"), 1);

  let descriptn = get_description_coin(&metadata);
  pp(&descriptn);
  assert!(descriptn == utf8(b"Dragon coin is the one coin to rule them all"), 1);

  let url = get_icon_url_coin(&metadata).extract().inner_url();//sui::url::Url
  pp(&url);
  assert!(url == (b"https://dukudama.sirv.com/Images/dragonGold001-512x512.png").to_ascii_string(), 1);

  let symbol = get_symbol_coin(&metadata);
  pp(&symbol);
  assert!(symbol == (b"DRAG").to_ascii_string(), 1);

  test_scenario::return_immutable<CoinMetadata<DRAGON>>(metadata);
  //let new_description = utf8(b"new_description");
  //update_description_coin(&mint_cap, &mut metadata, new_description);
};

sce.end();
}


#[test]
fun test_lock_tokens() {
    let admin = @0x11;
    let bob = @0xB0;

    let mut sce = test_scenario::begin(admin);
    {
        let otw = DRAGON{};
        init(otw, sce.ctx());
    };

    sce.next_tx(admin);
    {
        let mut mint_cap = sce.take_from_sender<MintCapability>();

        let duration = 5000;//in mimisec
        let test_clock = clock::create_for_testing(sce.ctx()); // 0 + 5000

        mint_locked(
            &mut mint_cap,
            REMAINING,
            bob,
            duration,
            &test_clock,
            sce.ctx()
        );
        assert!(mint_cap.total_minted == TOTAL_SUPPLY, EInvalidAmount);

        sce.return_to_sender(mint_cap);
        test_clock.destroy_for_testing();
    };

    sce.next_tx(bob);
    {
        let locker = sce.take_from_sender<Locker>();

        let duration = 5000;

        let mut test_clock = clock::create_for_testing(sce.ctx()); // 0

        test_clock.set_for_testing(duration);

        let amount = withdraw_locked(
            locker,
            &test_clock,
            sce.ctx()
        );
        assert!(amount == REMAINING, EInvalidAmount);
        test_clock.destroy_for_testing();
    };

    sce.next_tx(bob);
    {
        let coin = sce.take_from_sender<Coin<DRAGON>>();
        assert!(coin.balance().value() == REMAINING, EInvalidAmount);
        sce.return_to_sender(coin);
    };
    sce.end();
}


//Lock more than expected amount
#[test, expected_failure(abort_code = ESupplyExceeded)]
fun test_lock_overflow() {
    let admin = @0x11;
    let bob = @0xB0;

    let mut sce = test_scenario::begin(admin);
    {
        let otw = DRAGON{};
        init(otw, sce.ctx());
    };

    sce.next_tx(admin);
    {
        let mut mint_cap = sce.take_from_sender<MintCapability>();

        let duration = 5000;
        let test_clock = clock::create_for_testing(sce.ctx()); // 0 + 5000

        mint_locked(
            &mut mint_cap,
            100_000_000_000_000_001,
            bob,
            duration,
            &test_clock,
            sce.ctx()
        );
        sce.return_to_sender(mint_cap);
        test_clock.destroy_for_testing();
    };
    sce.end();
}

//Mint more than expected amount
#[test, expected_failure(abort_code = ESupplyExceeded)]
fun test_mint_overflow() {
    let admin = @0x11;
    let mut sce = test_scenario::begin(admin);
    {
        let otw = DRAGON{};
        init(otw, sce.ctx());
    };

    sce.next_tx(admin);
    {
        let mut mint_cap = sce.take_from_sender<MintCapability>();

        mint(
            &mut mint_cap,
            100_000_000_000_000_001,
            sce.ctx().sender(),
            sce.ctx()
        );
        sce.return_to_sender(mint_cap);
    };
    sce.end();
}


#[test, expected_failure(abort_code = ETokenLocked)]
fun test_withdraw_locked_before_unlock() {
    let admin = @0x11;
    let bob = @0xB0;

    let mut sce = test_scenario::begin(admin);
    {
        let otw = DRAGON{};
        init(otw, sce.ctx());
    };

    sce.next_tx(admin);
    {
        let mut mint_cap = sce.take_from_sender<MintCapability>();

        let duration = 5000;
        let test_clock = clock::create_for_testing(sce.ctx()); // 0 + 5000

        mint_locked(
            &mut mint_cap,
            REMAINING,
            bob,
            duration,
            &test_clock,
            sce.ctx()
        );

        assert!(mint_cap.total_minted == TOTAL_SUPPLY, EInvalidAmount);

        sce.return_to_sender(mint_cap);
        test_clock.destroy_for_testing();
    };

    sce.next_tx(bob);
    {
        let locker = sce.take_from_sender<Locker>();

        let duration = 4999;
        let mut test_clock = clock::create_for_testing(sce.ctx()); // 0

        test_clock.set_for_testing(duration);

        withdraw_locked(
            locker,
            &test_clock,
            sce.ctx()
        );
        test_clock.destroy_for_testing();
    };
    sce.end();
}