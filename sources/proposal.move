module package_addr::proposal;

use std::string::String;
use sui::table::{Self, Table};
use sui::url::{Url, new_unsafe_from_bytes};
use sui::clock::{Clock};
use sui::event;
use package_addr::dashboard::AdminCap;

const EDuplicateVote: u64 = 0;
const EProposalDelisted: u64 = 1;
const EProposalExpired: u64 = 2;

public enum ProposalStatus has store, drop {
    Active,
    Delisted,
}

public struct Proposal has key {
    id: UID,
    title: String,
    description: String,
    voted_yes_count: u64,
    voted_no_count: u64,
    expiration: u64,
    creator: address,
    status: ProposalStatus,
    voters: Table<address, bool>,
}

// === Admin Functions ===

public fun add(
    _admin_cap: &AdminCap,
    title: String,
    description: String,
    expiration: u64,
    ctx: &mut TxContext
): ID {
    let proposal = Proposal {
        id: object::new(ctx),
        title,
        description,
        voted_yes_count: 0,
        voted_no_count: 0,
        expiration,
        creator: ctx.sender(),
        status: ProposalStatus::Active,
        voters: table::new(ctx),
    };

    let id = proposal.id.to_inner();
    transfer::share_object(proposal);

    id
}

public fun remove(self: Proposal, _admin_cap: &AdminCap) {
    let Proposal {
        id,
        title: _,
        description: _,
        voted_yes_count: _,
        voted_no_count: _,
        expiration: _,
        status: _,
        voters,
        creator: _,
    } = self;

    table::drop(voters);
    object::delete(id)
}
