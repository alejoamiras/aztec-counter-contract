use aztec::macros::aztec;
pub mod test;

#[aztec]
pub contract Counter {
    use aztec::{
        macros::{functions::{initializer, internal, private, public, utility}, storage::storage},
        prelude::{AztecAddress, Map, PublicImmutable, PublicMutable},
    };
    use easy_private_state::EasyPrivateUint;
    use value_note::{balance_utils};

    
    /// @title Counter contract
    /// @notice Maintains private per-user counters and a public total counter.
    /// @dev Demonstrates mixed private/public execution and a utility view for tests.

    /// @dev Storage layout for the Counter contract
    /// @param owner The address with permission to increment others' counters
    /// @param counters Private counters mapped by `AztecAddress`
    /// @param total_counter Public total increments across all users
    #[storage]
    struct Storage<Context> {
        owner: PublicImmutable<AztecAddress, Context>,
        counters: Map<AztecAddress, EasyPrivateUint<Context>, Context>,
        total_counter: PublicMutable<u128, Context>,
    }

    /// @notice Initializes the contract
    /// @dev Public initializer sets the `owner`.
    /// @param owner The address of the owner
    #[public]
    #[initializer]
    fn constructor(owner: AztecAddress) {
        storage.owner.initialize(owner);
    }

    /// @notice Returns the owner of the contract
    /// @return AztecAddress The owner address
    #[public]
    fn get_owner() -> AztecAddress {
        storage.owner.read()
    }

    /// @notice Increments the caller's private counter
    /// @dev Private function. Also enqueues a public total counter increment.
    #[private]
    fn increment() {
        let sender = context.msg_sender();
        storage.counters.at(sender).add(1, sender, sender);
        // Enqueue public call
        Counter::at(context.this_address()).total_counter_increment_internal().enqueue(&mut context);
    }

    /// @notice Increments another user's private counter
    /// @dev Only callable by the owner. Also increments the public total counter.
    /// @param other_counter The address whose counter will be incremented
    #[private]
    fn increment_others(
        other_counter: AztecAddress
    ) {
        assert(storage.owner.read() == context.msg_sender(), "only owner");
        let counters = storage.counters;
        counters.at(other_counter).add(1, other_counter, context.msg_sender());
        Counter::at(context.this_address()).total_counter_increment_internal().enqueue(&mut context);
    }

    /// @notice Reads the public total counter
    /// @return u128 The current total counter value
    #[public]
    fn get_total_counter() -> u128 {
        storage.total_counter.read()
    }

    /// @notice Internal public function to increment the total counter
    /// @dev Enqueued by private functions
    #[public]
    #[internal]
    fn total_counter_increment_internal() {
        let current_value = storage.total_counter.read();
        storage.total_counter.write(current_value + 1);
    }

    /// @notice Utility function to read a user's private counter
    /// @dev Exposed for tests and off-chain apps; cannot be called from private/public fns
    /// @param owner Address whose counter to read
    /// @return Field The counter value as a Field
    #[utility]
    unconstrained fn get_counter(owner: AztecAddress) -> Field {
        let counters = storage.counters;
        balance_utils::get_balance(counters.at(owner).set)
    }
}
