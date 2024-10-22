//https://examples.sui.io/samples/nft.html
module package_addr::nft {
    use std::string::String;//utf8
    use sui::event;
		//use std::debug::print;
    //use std::error;
    //use std::timestamp;
		
    /// A Nft is a freely-transferable object. Owner can add new traits to their nft at any time and even change the image
    public struct Nft has key, store {
        id: UID,
        name: String,
        traits: vector<String>,
        url: String,
    }

    public struct MintEvent has copy, drop {
        nft_id: ID,
        minted_by: address,
    }

		//fun init(ctx: &mut TxContext) {    }

    public entry fun mint(
        name: String,
        traits: vector<String>,
        url: String,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);

        event::emit(MintEvent {
            nft_id: id.to_inner(),
            minted_by: ctx.sender(),
        });

        let nft = Nft { id, name, traits, url };
				transfer::public_transfer(nft, ctx.sender());
    }

    public entry fun transfer(nft: Nft, recipient: address) {
        transfer::public_transfer(nft, recipient);
    }
		
    // owner can add a new trait
    public fun add_trait(nft: &mut Nft, trait: String) {
        nft.traits.push_back(trait);
    }

    // owners can change the image
    public fun set_url(nft: &mut Nft, url: String) {
        nft.url = url;
    }

    /// owner can destroy the NFT and get a storage rebate
    public fun destroy(nft: Nft) {
        let Nft { id, url: _, name: _, traits: _ } = nft;
        id.delete()
    }

    // Getters for object fields/properties because they are private by default
    /// Get the Nft's `name`
    public fun name(nft: &Nft): String { nft.name }

    /// Get the Nft's `traits`
    public fun traits(nft: &Nft): &vector<String> { &nft.traits }

    /// Get the Nft's `url`
    public fun url(nft: &Nft): String { nft.url }
		

	#[test_only]
	use std::string::utf8;

	#[test]
	public fun test_nft() {
		use sui::test_scenario as ts;
		use std::debug::print as p;
		
		let admin: address = @0xA;
		let user1: address = @0x001;
    let mut scenario_val = ts::begin(admin);
    let sn = &mut scenario_val;
		//make sword
		ts::next_tx(sn, admin);
		{
			mint(utf8(b"nft_name"),
			vector[utf8(b"cat"), utf8(b"hungry"), utf8(b"sleepy")],
			utf8(b"nft.com"),ts::ctx(sn));
		};

		// transfer the sword from admin to user1
		ts::next_tx(sn, admin);
		{
			let nft = ts::take_from_sender<Nft>(sn);
			assert!(name(&nft) == utf8(b"nft_name"), 1);
			p(&url(&nft));
			assert!(url(&nft) == utf8(b"nft.com"), 1);

			p(traits(&nft));
			assert!(traits(&nft) == vector[utf8(b"cat"), utf8(b"hungry"), utf8(b"sleepy")], 1);

			transfer(nft, user1);
		};
		
		ts::next_tx(sn, user1);
		{
			let mut nft = ts::take_from_sender<Nft>(sn);
			set_url(&mut nft, utf8(b"nft2.com"));
			ts::return_to_sender(sn, nft);
		};

		ts::next_tx(sn, user1);
		{
			let nft = ts::take_from_sender<Nft>(sn);
			destroy(nft);
		};
//https://github.com/movebit/sui-course-2023/blob/main/part-5/lesson-1/src/nft-example/sources/artwork.move
		ts::end(scenario_val);
	}
}
