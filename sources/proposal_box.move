module package_addr::proposal_box;//must match this file name

public struct Proposalbox has key {
    id: UID,
    proposals_ids: vector<ID>
}
public struct AdminCap has key {
    id: UID,
}

fun init(ctx: &mut TxContext) {
    new(ctx);
    transfer::transfer(
        AdminCap {id: object::new(ctx)},
        ctx.sender()
    );
}

public fun new(ctx: &mut TxContext) {
    let box = Proposalbox {
        id: object::new(ctx),
        proposals_ids: vector[]
    };
    transfer::share_object(box);
}

public fun register_proposal(self: &mut Proposalbox, proposal_id: ID) {
    self.proposals_ids.push_back(proposal_id);
}


//----------== Test
#[test_only]
public fun issue_admin_cap(ctx: &mut TxContext) {
    transfer::transfer(
    AdminCap {id: object::new(ctx)},
    ctx.sender()
    );
}

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
        let proposalBox = tss.take_shared<Proposalbox>();
        assert!(proposalBox.proposals_ids.is_empty());
        ts::return_shared(proposalBox);
    };
    tss.end();
}