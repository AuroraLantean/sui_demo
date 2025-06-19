#[test_only]
module package_addr::proposal_box_test;//must match this file name

use sui::test_scenario as ts;
use package_addr::proposal::{Self, Proposal};
use package_addr::proposal_box::{Self, AdminCap};

const ENotImplemented: u64 = 0;

#[test]
fun test_add_proposal_with_admin_cap() {
    let admin = @0xA;

    let mut tss = ts::begin(admin);
    {
        proposal_box::issue_admin_cap(tss.ctx());
    };

    //make a new poposal
    tss.next_tx(admin);
    {
      let title = b"Hi".to_string();
      let desc = b"There".to_string();
      let admin_cap = tss.take_from_sender<AdminCap>();
      
      proposal::add( &admin_cap,title, desc, 2000000000, tss.ctx());
      
      ts::return_to_sender(&tss, admin_cap);
    };
    
    tss.next_tx(admin);
    {
        let prop1 = tss.take_shared<Proposal>();
        assert!(prop1.title() == b"Hi".to_string());
        assert!(prop1.description() == b"There".to_string());
        assert!(prop1.expiration() == 2000000000);
        assert!(prop1.voted_no_count() == 0);
        assert!(prop1.voted_yes_count() == 0);
        assert!(prop1.owner() == admin);
        //assert!(prop1.voter_registry().is_empty());
        ts::return_shared(prop1);
    };
    tss.end();
}

//EEmptyInventory: u64 = 3 from take_from_sender or take_from_address
#[test, expected_failure(abort_code = ts::EEmptyInventory)]
fun test_add_proposal_no_admin_cap(){
    //abort ENotImplemented
    let user = @0xB0B;
    let admin = @0xA01;

    let mut tss = ts::begin(admin);
    {
        proposal_box::issue_admin_cap(tss.ctx());
    };

    tss.next_tx(user);
    {
        let title = b"Hi".to_string();
        let desc = b"There".to_string();
        let admin_cap = tss.take_from_sender<AdminCap>();

        proposal::add(
            &admin_cap,
            title,
            desc,
            2000000000,
            tss.ctx()
        );
        ts::return_to_sender(&tss, admin_cap);
    };
    tss.end();
}








