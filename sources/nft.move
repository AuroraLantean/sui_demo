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
}
