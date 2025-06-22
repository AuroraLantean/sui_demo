#[test_only]
module package_addr::proposal_box_test;//must match this file name

use sui::test_scenario as ts;
use sui::clock;
use package_addr::proposal::{Self, Proposal, VoteProofNFT};
use package_addr::proposal_box::{Self, AdminCap, ProposalBox};

//const ENotImplemented: u64 = 0;
const EWrongVoteCount: u64 = 0;
const EWrongNftUrl: u64 = 1;
const EWrongStatus: u64 = 2;

fun add_proposal(admin_cap: &AdminCap, title: vector<u8>, desc: vector<u8>, ctx: &mut TxContext): ID  {
    //let title = b"title".to_string();
    let proposal_id = proposal::add(
        admin_cap,
        title.to_string(),
        desc.to_string(),
        300000000000,
        ctx
    );
    proposal_id
}

#[test]
fun test_register_proposal_as_admin() {
    let admin = @0xAD;
    let mut tss = ts::begin(admin);
    {
        let otw = proposal_box::new_otw(tss.ctx());
        proposal_box::issue_admin_cap(tss.ctx());
        proposal_box::new_shared_obj(otw, tss.ctx());
    };

    tss.next_tx(admin);
    {
        let mut box = tss.take_shared<ProposalBox>();

        let admin_cap = tss.take_from_sender<AdminCap>();

        let proposals_ids = box.proposals_ids();
        assert!(proposals_ids.is_empty());
    
        let proposal_id = add_proposal(&admin_cap, b"title", b"desc", tss.ctx());
    
        box.register(&admin_cap,proposal_id);

        let proposals_ids = box.proposals_ids();

        let proposal_exists = proposals_ids.contains(&proposal_id);

        assert!(proposal_exists);
        tss.return_to_sender(admin_cap);
        ts::return_shared(box);
    };
    tss.end();
}

#[test]
fun test_add_proposal_with_admin_cap() {
    let admin = @0xA;
    let bob = @0xB0;
    let alice = @0xA1;

    let mut tss = ts::begin(admin);
    {
        proposal_box::issue_admin_cap(tss.ctx());
    };

    //make a new poposal
    tss.next_tx(admin);
    {
      let admin_cap = tss.take_from_sender<AdminCap>();
      
      add_proposal(&admin_cap,b"title", b"desc",  tss.ctx());
      ts::return_to_sender(&tss, admin_cap);
    };
    
    tss.next_tx(admin);
    {
        let prop1 = tss.take_shared<Proposal>();
        assert!(prop1.title() == b"title".to_string());
        assert!(prop1.description() == b"desc".to_string());
        assert!(prop1.expiration() == 300000000000);
        assert!(prop1.voted_no_count() == 0);
        assert!(prop1.voted_yes_count() == 0);
        assert!(prop1.owner() == admin);
        assert!(prop1.voters().is_empty());
        ts::return_shared(prop1);
    };

    //Bob to vote
    tss.next_tx(bob);
    {
        let mut proposal = tss.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(tss.ctx());
        test_clock.set_for_testing(200000000000);

        proposal.vote(true, &test_clock, tss.ctx());

        assert!(proposal.voted_yes_count() == 1, EWrongVoteCount);
        ts::return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    
    //Check VoteProof NFT
    tss.next_tx(bob);
    {
        let vote_proof = tss.take_from_sender<VoteProofNFT>();

        assert!(vote_proof.vote_proof_url().inner_url() == b"https://thrangra.sirv.com/vote_yes_nft.jpg".to_ascii_string(), EWrongNftUrl);

        tss.return_to_sender(vote_proof);
    };
    
    //Alice to vote
    tss.next_tx(alice);
    {
        let mut proposal = tss.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(tss.ctx());
        test_clock.set_for_testing(200000000000);
        
        proposal.vote(true, &test_clock, tss.ctx());
        assert!(proposal.voted_yes_count() == 2, EWrongVoteCount);

        assert!(proposal.voted_no_count() == 0, EWrongVoteCount);

        ts::return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    tss.end();
}

#[test, expected_failure(abort_code = package_addr::proposal::EDuplicateVote)]
fun test_duplicate_voting() {
    let bob = @0xB0;
    let admin = @0xAd;
    let mut tss = ts::begin(admin);
    {
        proposal_box::issue_admin_cap(tss.ctx());
    };

    tss.next_tx(admin);
    {
        let admin_cap = tss.take_from_sender<AdminCap>();
        add_proposal(&admin_cap, b"title", b"desc", tss.ctx());
        ts::return_to_sender(&tss, admin_cap);
    };

    tss.next_tx(bob);
    {
        let mut proposal = tss.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(tss.ctx());
        test_clock.set_for_testing(200000000000);
        
        proposal.vote(true, &test_clock, tss.ctx());
        proposal.vote(true, &test_clock, tss.ctx());
        ts::return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    tss.end();
}


//EEmptyInventory: u64 = 3 from take_from_sender or take_from_address
#[test, expected_failure(abort_code = ts::EEmptyInventory)]
fun test_add_proposal_no_admin_cap(){
    //abort ENotImplemented
    let user = @0xB0;
    let admin = @0xad;

    let mut tss = ts::begin(admin);
    {
        proposal_box::issue_admin_cap(tss.ctx());
    };

    tss.next_tx(user);
    {
        let admin_cap = tss.take_from_sender<AdminCap>();

        add_proposal(&admin_cap, b"title", b"desc", tss.ctx());        ts::return_to_sender(&tss, admin_cap);
    };
    tss.end();
}

#[test]
fun test_change_proposal_status() {
    let admin = @0xAd;
    let mut tss = ts::begin(admin);
    {
        proposal_box::issue_admin_cap(tss.ctx());
    };

    tss.next_tx(admin);
    {
        let admin_cap = tss.take_from_sender<AdminCap>();

        add_proposal(&admin_cap, b"title", b"desc", tss.ctx());
        ts::return_to_sender(&tss, admin_cap);
    };

    tss.next_tx(admin);
    {
        let proposal = tss.take_shared<Proposal>();
        assert!(proposal.is_active());
        ts::return_shared(proposal);
    };

    tss.next_tx(admin);
    {
        let mut proposal = tss.take_shared<Proposal>();

        let admin_cap = tss.take_from_sender<AdminCap>();

        proposal.set_delisted_status(&admin_cap);
        assert!(!proposal.is_active(), EWrongStatus);
        ts::return_shared(proposal);
        tss.return_to_sender(admin_cap);
    };

    tss.next_tx(admin);
    {
        let mut proposal = tss.take_shared<Proposal>();

        let admin_cap = tss.take_from_sender<AdminCap>();

        proposal.set_active_status(&admin_cap);
        assert!(proposal.is_active(), EWrongStatus);

        ts::return_shared(proposal);
        tss.return_to_sender(admin_cap);
    };
    tss.end();
}





