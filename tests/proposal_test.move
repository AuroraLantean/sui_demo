#[test_only]
module package_addr::proposal_box_test;//must match this file name

// uncomment this line to import the module
// use proj1::proj1;
//const ENotImplemented: u64 = 0;

#[test]
fun test_proposal_add() {
    use sui::test_scenario as ts;
    use package_addr::proposal::{Self, Proposal};
    //use package_addr::proposal_box::{Self, Proposal_box};
    let admin = @0xA;

    let mut tss = ts::begin(admin);
    //make a new poposal
    {
      let title = b"Hi".to_string();
      let desc = b"There".to_string();
      proposal::add( title, desc, 2000000000, tss.ctx());
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

/*#[test, expected_failure(abort_code = ::proj1::proj1_tests::ENotImplemented)]
fun test_proj1_fail() {
    abort ENotImplemented
}*/

