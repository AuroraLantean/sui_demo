module package_addr::proposal_box;

public struct Proposal_box has key {
    id: UID,
    proposals_ids: vector<ID>
}

fun init(ctx: &mut TxContext) {
    new(ctx);
}

public fun new(ctx: &mut TxContext) {
    let box = Proposal_box {
        id: object::new(ctx),
        proposals_ids: vector[]
    };
    transfer::share_object(box);
}

public fun register_proposal(self: &mut Proposal_box, proposal_id: ID) {
    self.proposals_ids.push_back(proposal_id);
}

//----------== Test
#[test]
fun test_module_init() {
    use sui::test_scenario as ts;
    let admin = @0xA;
   
    //init this module
    let mut tss = ts::begin(admin);
    {
        init(tss.ctx());
    };

    //check initial shared objects, easier to test it here without writing read functions
    tss.next_tx(admin);
    {
        let proposalBox = tss.take_shared<Proposal_box>();
        assert!(proposalBox.proposals_ids.is_empty());
        ts::return_shared(proposalBox);
    };
    tss.end();
}