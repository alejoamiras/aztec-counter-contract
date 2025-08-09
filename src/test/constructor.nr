use crate::{Counter, test::utils};

#[test]
unconstrained fn constructor_success() {
    // Create Alice and Bob's addresses and deploy the contract
    let (env, contract_address, alice, _) = utils::setup_contract();
    assert(alice == Counter::at(contract_address).get_owner().call(&mut env.public()));
}
