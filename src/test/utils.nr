use crate::Counter;
use aztec::{
    prelude::AztecAddress, 
    oracle::execution::get_contract_address, 
    test::helpers::test_environment::TestEnvironment,
    test::helpers::cheatcodes,
};

pub unconstrained fn setup_contract() -> (&mut TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    // Setup env, generate keys
    let mut env = TestEnvironment::new();
    let owner = env.create_account(1);
    let user = env.create_account(2);
    let contract_address = deploy_contract(&mut env, owner);

    (&mut env, contract_address, owner, user)
}

pub unconstrained fn deploy_contract(
    env: &mut TestEnvironment,
    owner: AztecAddress,
) -> AztecAddress {
    let initializer_call_interface = Counter::interface().constructor(owner);
    let contract_address = env
        .deploy_self("Counter")
        .with_public_void_initializer(owner, initializer_call_interface)
        .to_address();

    contract_address
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