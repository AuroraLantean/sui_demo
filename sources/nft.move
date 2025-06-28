//https://examples.sui.io/samples/nft.html
module package_addr::nft;
    use std::string::String;//utf8
    use sui::event;
		//use sui::url::{Self, Url};  
		//use std::debug::print;
    //use std::error;
    //use std::timestamp;
		
    /// A Nft is a freely-transferable object. Owner can add new traits to their nft at any time and even change the image
    public struct Nft has key, store {
        id: UID,
        name: String,
				description: String,
        traits: vector<String>,
        url: String,//Url
    }

    public struct MintEvent has copy, drop {
        nft_id: ID,
        minted_by: address,
    }

		//fun init(ctx: &mut TxContext) {    }

    public entry fun mint(
        name: String,
				description: String,
        traits: vector<String>,
        url: String,
        ctx: &mut TxContext
    ) {
        let id = object::new(ctx);

        event::emit(MintEvent {
            nft_id: id.to_inner(),
            minted_by: ctx.sender(),
        });

        let nft = Nft { id, name, description, traits, url };
				//url::new_unsafe_from_bytes(b"icon_url")
				transfer::public_transfer(nft, ctx.sender());
    }

    public entry fun transfer(nft: Nft, recipient: address) {
        transfer::public_transfer(nft, recipient);
    }
		
    //------== Only by Owner
    public entry fun add_trait(nft: &mut Nft, trait: String) {
        nft.traits.push_back(trait);
    }
    public entry fun update_url(nft: &mut Nft, url: String) {
        nft.url = url;
    }
    public entry fun update_description(nft: &mut Nft, new_description: String) {
        nft.description = new_description;
    }
    public entry fun burn(nft: Nft) {
        let Nft { id, description: _, url: _, name: _, traits: _ } = nft;
        id.delete()
    }
		//------== 
    
		// Getters for object fields/properties because they are private by default
    public fun name(nft: &Nft): String { nft.name }
    public fun description(nft: &Nft): &String { &nft.description }
    public fun traits(nft: &Nft): &vector<String> { &nft.traits }
    public fun url(nft: &Nft): String { nft.url }
		// &nft.url with type of &Url
		

	#[test_only] use std::string::utf8;
  #[test_only] use sui::test_scenario::{begin};
	#[test]
	public fun test_nft() {
		use std::debug::print as p;
		
		let admin: address = @0xA;
		let user1: address = @0x01;
		//make sword
    let mut sce = begin(admin);
		{
			mint(utf8(b"nft_name"), utf8(b"description"),
			vector[utf8(b"cat"), utf8(b"hungry"), utf8(b"sleepy")],
			utf8(b"nft.com"),sce.ctx());
		};

		// transfer the sword from admin to user1
		sce.next_tx( admin);
		{
			let nft = sce.take_from_sender<Nft>();
			assert!(name(&nft) == utf8(b"nft_name"), 1);
			p(&url(&nft));
			assert!(url(&nft) == utf8(b"nft.com"), 1);

			p(traits(&nft));
			assert!(traits(&nft) == vector[utf8(b"cat"), utf8(b"hungry"), utf8(b"sleepy")], 1);

			transfer(nft, user1);
		};
		
		sce.next_tx( user1);
		{
			let mut nft = sce.take_from_sender<Nft>();
			update_url(&mut nft, utf8(b"nft2.com"));
			sce.return_to_sender( nft);
		};

		sce.next_tx( user1);
		{
			let nft = sce.take_from_sender<Nft>();
			burn(nft);
		};
//https://github.com/movebit/sui-course-2023/blob/main/part-5/lesson-1/src/nft-example/sources/artwork.move
		sce.end();
	}

