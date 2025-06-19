module package_addr::proposal_box;//must match this file name

use sui::types;
const EDuplicateProposal: u64 = 0;
const EInvalidOtw: u64 = 1;

public struct ProposalBox has key {
    id: UID,
    proposals_ids: vector<ID>
}
public fun proposals_ids(self: &ProposalBox): &vector<ID> {
    &self.proposals_ids
}

public struct AdminCap has key {
    id: UID,
}
public struct PROPOSAL_BOX has drop {}

fun init(otw: PROPOSAL_BOX, ctx: &mut TxContext) {
    //let admin_cap = AdminCap {id: object::new(ctx)};
    new_shared_obj(otw, ctx);
    transfer::transfer(
      AdminCap {id: object::new(ctx)},
      ctx.sender()
    );
}
public fun new_shared_obj(otw: PROPOSAL_BOX, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness(&otw), EInvalidOtw);
    
    let box = ProposalBox {
        id: object::new(ctx),
        proposals_ids: vector[]
    };
    transfer::share_object(box);
}

public fun register(self: &mut ProposalBox, proposal_id: ID) {
    assert!(!self.proposals_ids.contains(&proposal_id), EDuplicateProposal);
    
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
#[test_only]
public fun new_otw(_ctx: &mut TxContext): PROPOSAL_BOX {
    PROPOSAL_BOX {}
}

#[test]
fun test_module_init() {
    use sui::test_scenario as ts;
    let admin = @0xA;

    //init this module
    let mut tss = ts::begin(admin);
    {
      let otw = PROPOSAL_BOX{};
        init(otw,tss.ctx());
    };

    //check initial conditions of shared objects here, OR make read functions because the field shared objects can only be accessed within the module
    tss.next_tx(admin);
    {
        let box = tss.take_shared<ProposalBox>();
        assert!(box.proposals_ids.is_empty());
        ts::return_shared(box);
    };
    tss.end();
}