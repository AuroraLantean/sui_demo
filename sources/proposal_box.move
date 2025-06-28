module package_addr::proposal_box;

use sui::types;
const EDuplicateProposal: u64 = 0;
const EInvalidOtw: u64 = 1;
const EVecIndexOutOfBound: u64 = 2;

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
public struct PROPOSAL_BOX has drop {}//must be capitalized of this module name

fun init(otw: PROPOSAL_BOX, ctx: &mut TxContext) {
    new_shared_obj(otw, ctx);
    transfer::transfer(
      AdminCap {id: object::new(ctx)},
      ctx.sender()
    );
}
public fun new_shared_obj(otw: PROPOSAL_BOX, ctx: &mut TxContext) {
    assert!(types::is_one_time_witness(&otw), EInvalidOtw);
    //let admin_cap = AdminCap {id: object::new(ctx)};    
    let box = ProposalBox {
        id: object::new(ctx),
        proposals_ids: vector[]
    };
    transfer::share_object(box);
}

public fun register(self: &mut ProposalBox, _admin_cap: &AdminCap, proposal_id: ID) {
    assert!(!self.proposals_ids.contains(&proposal_id), EDuplicateProposal);
    
    self.proposals_ids.push_back(proposal_id);
}
public fun remove(self: &mut ProposalBox, _admin_cap: &AdminCap, index: u64) {
    assert!(index < self.proposals_ids.length(), EVecIndexOutOfBound);
    
    self.proposals_ids.remove( index);
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
    use sui::test_scenario as tsce;
    let admin = @0xA;

    //init this module
    let mut sce = tsce::begin(admin);
    {
      let otw = PROPOSAL_BOX{};
        init(otw,sce.ctx());
    };

    //check initial conditions of shared objects here, OR make read functions because the field shared objects can only be accessed within the module
    sce.next_tx(admin);
    {
        let box = sce.take_shared<ProposalBox>();
        assert!(box.proposals_ids.is_empty());
        tsce::return_shared(box);
    };
    sce.end();
}