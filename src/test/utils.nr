use crate::Counter;
use aztec::{prelude::AztecAddress, test::helpers::test_environment::TestEnvironment};

pub unconstrained fn setup_contract(
    with_account_contracts: bool,
) -> (&mut TestEnvironment, AztecAddress, AztecAddress, AztecAddress) {
    // Setup env, generate keys
    let mut env = TestEnvironment::new();
    let (owner, user) = if with_account_contracts {
        let owner = env.create_account_contract(1);
        let user = env.create_account_contract(2);
        (owner, user)
    } else {
        let owner = env.create_account(1);
        let user = env.create_account(2);
        (owner, user)
    };

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
    env.advance_block_by(1);

    contract_address
}
