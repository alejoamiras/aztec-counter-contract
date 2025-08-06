use aztec::macros::aztec;
pub mod test;

#[aztec]
pub contract Counter {
    // aztec library imports
    use aztec::{
        macros::{functions::{initializer, internal, private, public, utility}, storage::storage},
        prelude::{AztecAddress, Map, PublicImmutable, PublicMutable},
    };
    use easy_private_state::EasyPrivateUint;
    use value_note::{balance_utils};

    // @param owner The address of the owner
    // @param counter A numerical value
    #[storage]
    struct Storage<Context> {
        owner: PublicImmutable<AztecAddress, Context>,
        counters: Map<AztecAddress, EasyPrivateUint<Context>, Context>,
        total_counter: PublicMutable<u128, Context>,
    }

    /// @dev Initialize the contract
    /// @param owner The address of the owner
    #[public]
    #[initializer]
    fn constructor(owner: AztecAddress) {
        storage.owner.initialize(owner);
    }

    /// @dev Retrieves the owner of the contract
    /// @return The owner of the contract
    #[public]
    fn get_owner() -> AztecAddress {
        storage.owner.read()
    }

    /// @dev Increments the counter
    #[private]
    fn increment() {
        let sender = context.msg_sender();
        let counters = storage.counters;
        counters.at(sender).add(1, sender, sender);
        // Enqueue public call
        Counter::at(context.this_address()).total_counter_increment_internal().enqueue(&mut context);
    }

    /// @dev Retrieves the counter value
    /// @return The current counter value
    #[public]
    fn get_total_counter() -> u128 {
        storage.total_counter.read()
    }

    /// @dev Increments the counter
    #[public]
    #[internal]
    fn total_counter_increment_internal() {
        let current_value = storage.total_counter.read();
        storage.total_counter.write(current_value + 1);
    }

    #[utility]
    unconstrained fn get_counter(owner: AztecAddress) -> Field {
        let counters = storage.counters;
        balance_utils::get_balance(counters.at(owner).set)
    }
}
