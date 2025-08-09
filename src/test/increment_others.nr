use crate::{Counter, test::utils};

#[test]
unconstrained fn increment_others_success() {
    // Create Alice and Bob's addresses and deploy the contract
    let (env, contract_address, alice, bob) = utils::setup_contract();

    // Get initial total counter
    let mut total_counter =
        Counter::at(contract_address).get_total_counter().call(&mut env.public());
    assert(total_counter == 0);

    // Get initial bob counter (leveraging the utility function)
    let mut bob_counter = utils::get_private_counter(bob, contract_address);
    assert(bob_counter == 0);

    // We impersonate Alice (she is also the owner of the contract)
    env.impersonate(alice);
    // Call increment from Alice
    Counter::at(contract_address).increment_others(bob).call(&mut env.private());
    
    // Get total counter again
    total_counter = Counter::at(contract_address).get_total_counter().call(&mut env.public());
    assert(total_counter == 1);

    // Get bob's counter again
    bob_counter = utils::get_private_counter(bob, contract_address);
    assert(bob_counter == 1);
}

#[test(should_fail_with = "only owner")]
unconstrained fn increment_others_fail() {
    // Create Alice and Bob's addresses and deploy the contract
    let (env, contract_address, _, bob) = utils::setup_contract();
    // We impersonate Bob (who is not the owner)
    env.impersonate(bob);
    // Call increment from Bob
    Counter::at(contract_address).increment_others(bob).call(&mut env.private());
}
