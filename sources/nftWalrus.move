//https://github.com/paulgs9988/sui_nft_tutorial
//https://github.com/MystenLabs/sui/tree/main/examples/trading/contracts/demo/sources
module package_addr::nft_walrus {
	use sui::package;   //For package publishing
	use sui::display;   //For NFT metadata display
	use sui::balance::{Self, Balance};
	use sui::sui::SUI;  //For the sui token type
	use sui::coin::{Self, Coin};
	use std::string::{Self, String};

	public struct NftWalrus has key, store {
		id: UID,
		name: String,
		description: String,
		walrus_blob_id: String,
		walrus_sui_object: String,
		balance: Balance<SUI>
	}

	//OTW to create display
	public struct NFT_WALRUS has drop{}
	const ENO_EMPTY_NAME: u64 = 0;
	const ENO_EMPTY_BLOB_ID: u64 = 1;

	//Upload the NFT image at https://publish.walrus.site/ : epoc is how long the uploaded data can last. Currently 1 epoc is about 1 day; copy the walrus_blob_id and Object Id
	fun init(witness: NFT_WALRUS, ctx: &mut TxContext) {
		let keys = vector[
			string::utf8(b"name"),
			string::utf8(b"description"),
			string::utf8(b"image_url"),
		];
		
		let values = vector[
			string::utf8(b"{name}"),
			string::utf8(b"{description}"),
			string::utf8(b"https://aggregator.walrus-testnet.walrus.space/v1/{walrus_blob_id}")
		];
		
		let publisher = package::claim(witness, ctx);

    // Get a new `Display` object for the `Hero` type.
		let mut display_obj = display::new_with_fields<NftWalrus>(
				&publisher, keys, values, ctx
		);
    // Commit first version of `Display` to apply changes.
		display::update_version(&mut display_obj);
		
		transfer::public_transfer(publisher, tx_context::sender(ctx));
		transfer::public_transfer(display_obj, tx_context::sender(ctx));
	}

	//Upload the NFT image at https://publish.walrus.site/ : epoc is how long the uploaded data can last. Currently 1 epoc is about 1 day; copy the walrus_blob_id and Object Id
	public entry fun mint_nft(
		name: String,
		description: String,
		walrus_blob_id: String,
		walrus_sui_object: String,
		ctx: &mut TxContext
	) {
		assert!(!string::is_empty(&name), ENO_EMPTY_NAME);
		assert!(!string::is_empty(&walrus_blob_id), ENO_EMPTY_BLOB_ID);

		let nft = NftWalrus {
			id: object::new(ctx),
			name,
			description,
			walrus_blob_id,
			walrus_sui_object,
			balance: balance::zero()
		};

		transfer::transfer(nft, tx_context::sender(ctx));
	}

	public entry fun deposit_sui(
		self: &mut NftWalrus,
		payment: &mut Coin<SUI>,
		amount: u64,// Amount of SUI in MIST
	) {
		let coin_balance = coin::balance_mut(payment);
		
		let paid = balance::split(coin_balance, amount);
		
		// Join the split amount into the NFT's balance
		balance::join(&mut self.balance, paid);
	}

	public entry fun withdraw_sui(
		self: &mut NftWalrus,
		amount: u64,// Amount to withdraw in MIST
		ctx: &mut TxContext
	) {
		let withdrawn = coin::from_balance(
				balance::split(&mut self.balance, amount), 
				ctx
		);
		
		// Transfer the new coin to the transaction sender
		transfer::public_transfer(withdrawn, tx_context::sender(ctx));
	}
	
	//------== Getter Functions
	public fun name(self: &NftWalrus): &String { &self.name }
	public fun description(self: &NftWalrus): &String { &self.description }
	public fun walrus_blob_id(self: &NftWalrus): &String { &self.walrus_blob_id }
	public fun walrus_sui_object(self: &NftWalrus): String { self.walrus_sui_object }
}