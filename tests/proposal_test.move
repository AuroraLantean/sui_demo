#[test_only]
module package_addr::proposal_box_test;

use sui::test_scenario::{begin, return_shared, return_to_sender, EEmptyInventory};
use sui::clock;
use package_addr::proposal::{Self, Proposal, VoteProofNFT};
use package_addr::proposal_box::{Self, AdminCap, ProposalBox};

//const ENotImplemented: u64 = 0;
const EWrongVoteCount: u64 = 0;
const EWrongNftUrl: u64 = 1;
const EWrongStatus: u64 = 2;
const CExpiry: u64 = 1782117752000;

fun new_proposal(admin_cap: &AdminCap, title: vector<u8>, desc: vector<u8>, ctx: &mut TxContext): ID  {
    //let title = b"title".to_string();
    let proposal_id = proposal::new(
        admin_cap,
        title.to_string(),
        desc.to_string(),
        CExpiry,
        ctx
    );
    proposal_id
}

#[test]
fun test_register_proposal_as_admin() {
    let admin = @0xAD;
    let mut sce = begin(admin);
    {
        let otw = proposal_box::new_otw(sce.ctx());
        proposal_box::issue_admin_cap(sce.ctx());
        proposal_box::new_shared_obj(otw, sce.ctx());
    };

    //new proposal, register, remove
    sce.next_tx(admin);
    {
        let mut box = sce.take_shared<ProposalBox>();

        let admin_cap = sce.take_from_sender<AdminCap>();

        let proposals_ids = box.proposals_ids();
        assert!(proposals_ids.is_empty());
    
        let proposal_id = new_proposal(&admin_cap, b"title", b"desc", sce.ctx());
    
        box.register(&admin_cap,proposal_id);

        let proposals_ids = box.proposals_ids();

        let proposal_exists = proposals_ids.contains(&proposal_id);
        assert!(proposal_exists);

        box.remove(&admin_cap,0);
        let proposals_ids = box.proposals_ids();
        assert!(proposals_ids.is_empty());

        sce.return_to_sender(admin_cap);
        return_shared(box);
    };
    sce.end();
}

#[test]
fun test_new_proposal_with_admin_cap() {
    let admin = @0xA;
    let bob = @0xB0;
    let alice = @0xA1;

    let mut sce = begin(admin);
    {
        proposal_box::issue_admin_cap(sce.ctx());
    };

    //make a new poposal
    sce.next_tx(admin);
    {
      let admin_cap = sce.take_from_sender<AdminCap>();
      
      new_proposal(&admin_cap,b"title", b"desc",  sce.ctx());
      return_to_sender(&sce, admin_cap);
    };
    
    sce.next_tx(admin);
    {
        let prop1 = sce.take_shared<Proposal>();
        assert!(prop1.title() == b"title".to_string());
        assert!(prop1.description() == b"desc".to_string());
        assert!(prop1.expiration() == CExpiry);
        assert!(prop1.voted_no_count() == 0);
        assert!(prop1.voted_yes_count() == 0);
        assert!(prop1.owner() == admin);
        assert!(prop1.voters().is_empty());
        return_shared(prop1);
    };

    //Bob to vote
    sce.next_tx(bob);
    {
        let mut proposal = sce.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(sce.ctx());
        test_clock.set_for_testing(200000000000);

        proposal.vote(true, &test_clock, sce.ctx());

        assert!(proposal.voted_yes_count() == 1, EWrongVoteCount);
        return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    
    //Check VoteProof NFT
    sce.next_tx(bob);
    {
        let vote_proof = sce.take_from_sender<VoteProofNFT>();

        assert!(vote_proof.vote_proof_url().inner_url() == b"https://dukudama.sirv.com/Images/vote_yes_nft.jpg".to_ascii_string(), EWrongNftUrl);

        sce.return_to_sender(vote_proof);
    };
    
    //Alice to vote
    sce.next_tx(alice);
    {
        let mut proposal = sce.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(sce.ctx());
        test_clock.set_for_testing(200000000000);
        
        proposal.vote(true, &test_clock, sce.ctx());
        assert!(proposal.voted_yes_count() == 2, EWrongVoteCount);

        assert!(proposal.voted_no_count() == 0, EWrongVoteCount);

        return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    sce.end();
}

#[test, expected_failure(abort_code = package_addr::proposal::EDuplicateVote)]
fun test_duplicate_voting() {
    let bob = @0xB0;
    let admin = @0xAd;
    let mut sce = begin(admin);
    {
        proposal_box::issue_admin_cap(sce.ctx());
    };

    sce.next_tx(admin);
    {
        let admin_cap = sce.take_from_sender<AdminCap>();
        new_proposal(&admin_cap, b"title", b"desc", sce.ctx());
        return_to_sender(&sce, admin_cap);
    };

    sce.next_tx(bob);
    {
        let mut proposal = sce.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(sce.ctx());
        test_clock.set_for_testing(200000000000);
        
        proposal.vote(true, &test_clock, sce.ctx());
        proposal.vote(true, &test_clock, sce.ctx());
        return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    sce.end();
}


//EEmptyInventory: u64 = 3 from take_from_sender or take_from_address
#[test, expected_failure(abort_code = EEmptyInventory)]
fun test_new_proposal_no_admin_cap(){
    //abort ENotImplemented
    let user = @0xB0;
    let admin = @0xad;

    let mut sce = begin(admin);
    {
        proposal_box::issue_admin_cap(sce.ctx());
    };

    sce.next_tx(user);
    {
        let admin_cap = sce.take_from_sender<AdminCap>();

        new_proposal(&admin_cap, b"title", b"desc", sce.ctx());        return_to_sender(&sce, admin_cap);
    };
    sce.end();
}

#[test, expected_failure(abort_code = package_addr::proposal::EProposalExpired)]
fun test_voting_expiration() {
    let bob = @0xB0;
    let admin = @0xAd;

    let mut sce = begin(admin);
    {
        proposal_box::issue_admin_cap(sce.ctx());
    };

    sce.next_tx(admin);
    {
        let admin_cap = sce.take_from_sender<AdminCap>();

        new_proposal(&admin_cap, b"title", b"desc", sce.ctx());

        return_to_sender(&sce, admin_cap);
    };

    sce.next_tx(bob);
    {
        let mut proposal = sce.take_shared<Proposal>();

        let mut test_clock = clock::create_for_testing(sce.ctx());

        test_clock.set_for_testing(CExpiry);

        proposal.vote(true, &test_clock, sce.ctx());

        return_shared(proposal);
        test_clock.destroy_for_testing();
    };
    sce.end();
}

#[test]
fun test_change_proposal_status() {
    let admin = @0xAd;
    let mut sce = begin(admin);
    {
        proposal_box::issue_admin_cap(sce.ctx());
    };

    sce.next_tx(admin);
    {
        let admin_cap = sce.take_from_sender<AdminCap>();

        new_proposal(&admin_cap, b"title", b"desc", sce.ctx());
        return_to_sender(&sce, admin_cap);
    };

    sce.next_tx(admin);
    {
        let proposal = sce.take_shared<Proposal>();
        assert!(proposal.is_active());
        return_shared(proposal);
    };

    sce.next_tx(admin);
    {
        let mut proposal = sce.take_shared<Proposal>();

        let admin_cap = sce.take_from_sender<AdminCap>();

        proposal.set_delisted_status(&admin_cap);
        assert!(!proposal.is_active(), EWrongStatus);
        return_shared(proposal);
        sce.return_to_sender(admin_cap);
    };

    sce.next_tx(admin);
    {
        let mut proposal = sce.take_shared<Proposal>();

        let admin_cap = sce.take_from_sender<AdminCap>();

        proposal.set_active_status(&admin_cap);
        assert!(proposal.is_active(), EWrongStatus);

        return_shared(proposal);
        sce.return_to_sender(admin_cap);
    };
    sce.end();
}

//EEmptyInventory: u64 = 3 from take_from_sender or take_from_address
#[test, expected_failure(abort_code = EEmptyInventory)]
fun test_delete_proposal() {
    let admin = @0xAd;

    let mut sce = begin(admin);
    {
        proposal_box::issue_admin_cap(sce.ctx());
    };

    sce.next_tx(admin);
    {
        let admin_cap = sce.take_from_sender<AdminCap>();

        new_proposal(&admin_cap, b"title", b"desc", sce.ctx());
        return_to_sender(&sce, admin_cap);
    };

    sce.next_tx(admin);
    {
        let proposal = sce.take_shared<Proposal>();

        let admin_cap = sce.take_from_sender<AdminCap>();

        proposal.delete(&admin_cap);
        sce.return_to_sender(admin_cap);
    };

    //take deleted object
    sce.next_tx(admin);
    {
        let proposal = sce.take_shared<Proposal>();
        return_shared(proposal);
    };
    sce.end();
}



