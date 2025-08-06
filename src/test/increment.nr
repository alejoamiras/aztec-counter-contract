use crate::{Counter, test::utils};
use aztec::{
    prelude::AztecAddress,
    oracle::execution::get_contract_address, 
    test::helpers::cheatcodes,
};

#[test]
unconstrained fn increment_success() {
    // Create Alice and Bob's addresses and deploy the contract
    let (env, contract_address, alice, _) = utils::setup_contract(false);

    // Get initial total counter
    let mut total_counter =
        Counter::at(contract_address).get_total_counter().call(&mut env.public());
    assert(total_counter == 0);

    // Get initial alice counter (leveraging the utility function)
    let mut alice_counter = get_private_counter(alice, contract_address);
    assert(alice_counter == 0);

    // We impersonate Alice (she is also the owner of the contract)
    env.impersonate(alice);
    // Call increment from Alice
    Counter::at(contract_address).increment().call(&mut env.private());
    
    // Get total counter again
    total_counter = Counter::at(contract_address).get_total_counter().call(&mut env.public());
    assert(total_counter == 1);

    // Get alice's counter again
    alice_counter = get_private_counter(alice, contract_address);
    assert(alice_counter == 1);
}


unconstrained fn get_private_counter(user: AztecAddress, contract_address: AztecAddress) -> Field {
    // cheatcodes set address to counter
    let current_contract_address = get_contract_address();
    cheatcodes::set_contract_address(contract_address);
    // get utility function call
    let private_counter = Counter::get_counter(user);
    // re-set contract address to original
    cheatcodes::set_contract_address(current_contract_address);
    // return the counter
    private_counter
}