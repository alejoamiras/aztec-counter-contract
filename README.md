> 🎮 **Want to skip ahead and play with privacy?** Try our [Interactive Playground](https://aztec-private-playground-59.lovable.app/) to experiment with private counters right now!

# 🎯 The Private Counter Adventure: An Aztec.nr Tutorial

*Welcome, developer! Today we're building something cool - a Counter that keeps individual numbers private while making the total public. Think of it as a sealed box where only you can see your number inside, but everyone can verify the total sum of all the numbers inside the box.*

**Quick Navigation:**
- [Setting Up](#️-setting-up-your-environment)
- [Understanding the Contract](#-chapter-2-understanding-the-contract)
- [Testing](#-chapter-3-testing-the-contract)
- [Experiments](#-chapter-4-experiment-time)
- [Interactive Playground](#-interactive-playground) 🎮
- [Troubleshooting](#-errors-you-might-encounter)

## 📚 What You'll Learn

By the end of this tutorial, you'll understand:
- **Public Initializers**: How constructors work in Aztec and why they must be public when setting public state
- **Private Functions**: How to declare and use private functions that execute locally
- **Cross-Context Calls**: How to safely call public functions from private contexts using enqueuing
- **Utility Functions**: How to leverage unconstrained functions for testing private state
- **Test Environment**: How to set up and write tests using Aztec's TXE (Test eXecution Environment)
- **Contract Deployment**: How to deploy smart contracts through test utilities
- **Privacy Patterns**: Best practices for maintaining privacy while updating public state

## 🏰 Chapter 1: What We're Building

Picture this: You're building a system where each person's vote count must remain private, but the total votes must be public. Or maybe a game where players accumulate secret points, but the leaderboard shows total activity. That's exactly what we're about to build!

Our Counter contract has these key features:
- 🔐 **Private counters**: Each user has their own private counter that only they can see
- 👑 **Owner privileges**: One address can increment anyone's counter (useful for admins or game masters)
- 📊 **Public total**: Everyone can see the total count across all users
- 🔍 **Test utilities**: A special function lets tests verify private values

### 🛠️ Setting Up Your Environment

First, let's get our tools ready! You'll need Docker running, then install the Aztec toolkit:

```bash
# This installs all the Aztec development tools
bash -i <(curl -s https://install.aztec.network)
```

This gives you:
- `aztec` - Your command center for running Aztec networks
- `aztec-nargo` - The Noir compiler for writing zero-knowledge contracts
- `aztec-up` - Tool updater for staying current with releases
- `aztec-wallet` - CLI tool for interacting with contracts

## 🎭 Chapter 2: Understanding the Contract

Open `src/main.nr` and let's explore how it works. At the top, you'll see our storage layout:

```noir
#[storage]
struct Storage<Context> {
    owner: PublicImmutable<AztecAddress>,      // The admin address - set once!
    counters: Map<AztecAddress, EasyPrivateUint>, // Private storage for each user
    total_counter: PublicMutable<u128>,        // The public running total
}
```

### 🎪 Part 1: The Constructor

Let's start with initialization. Our constructor is simple but important:

```noir
#[public]
#[initializer]
fn constructor(owner: AztecAddress) {
    storage.owner.initialize(owner);
}
```

When deployed, this sets the owner - the only address that can increment other people's counters. Think of it as appointing an admin who can award points or correct balances.

**Why is the constructor public?** Because the owner address is stored in public storage (`PublicImmutable`).

### 🎪 Part 2: Your Personal Counter

Now for the fun part! When you call `increment()`, magic happens:

```noir
#[private]
fn increment() {
    let sender = context.msg_sender();
    storage.counters.at(sender).add(1, sender, sender);
    Counter::at(context.this_address()).total_counter_increment_internal().enqueue(&mut context);
}
```

Notice something special? This function is `#[private]` - and as such, it executes locally, not on the blockchain! Your counter increases privately, then it enqueues a public call to update the total.

**Privacy Protection:** Why enqueue instead of updating immediately? If we updated the public total instantly, observers could see the exact moment of each increment, potentially linking it to your transaction. The delay protects you from being "doxxed" by timing analysis!

### 🎪 Part 3: Owner-Only Functions

The owner has special privileges:

```noir
#[private]
fn increment_others(address: AztecAddress) {
    assert(storage.owner.read() == context.msg_sender(), "only owner");
    let counters = storage.counters;
    counters.at(other_counter).add(1, other_counter, context.msg_sender());
    Counter::at(context.this_address()).total_counter_increment_internal().enqueue(&mut context);
}
```

Only the owner can increment someone else's counter. Try it as a regular user and you'll hit the access control: "only owner"!

## 🧪 Chapter 3: Testing the Contract

Time to see our contract in action! We don't even need the full Aztec network running - just compile and test:

```bash
# First, compile the contract
aztec-nargo compile

# Now run the test suite
aztec test
```

### 🔬 Test Story 1: The Birth (`constructor.nr`)

Our first test checks if the owner was properly crowned:
```
✓ Does the constructor set the right owner?
```

### 🔬 Test Story 2: Counting in Secret (`increment.nr`)

This test has Alice increment her counter:
```
✓ Alice starts with 0
✓ Alice calls increment()
✓ Alice's private counter is now 1
✓ The public total is also 1
```

The beauty? Only Alice knows her counter is 1. Everyone else just sees the total increased!

### 🔬 Test Story 3: The Owner's Power (`increment_others.nr`)

Watch as the owner helps Bob:
```
✓ Bob starts with 0
✓ Owner increments Bob's counter
✓ Bob's private counter is now 1
✓ Total counter shows 1
✗ Non-owner tries to increment Bob... REJECTED!
```

## 🎮 Chapter 4: Experiment Time!

Now it's your turn to experiment! Here are some challenges to try:

### Challenge 1: Double Points
Change the increment to add 2 instead of 1:
```noir
counter.add(2);  // Double the fun!
```
Don't forget to update the tests to expect 2 instead of 1!

### Challenge 2: Add a Multiplier
What if the owner could give someone 10x points? Add a new function:
```noir
#[private]
fn super_increment(address: AztecAddress, amount: u128) {
    assert(storage.owner.is_eq(context.msg_sender()), "only owner");
    let mut counter = storage.counters.at(address);
    counter.add(amount);
    Counter::at(context.this_address()).total_counter_increment_internal().enqueue(amount);
}
```



## 🚨 Errors You Might Encounter

**"My code won't compile!"**
- Make sure you're on the right version: `aztec-up 1.2.0`
- Check that Docker is running

**"I can't read private values!"**
- Remember: only `#[utility]` functions can read private state for testing
- Never try to access `.set` directly - use the proper helper functions

**"The tests are failing!"**
- Did you change the increment amount? Update your test expectations!
- Run `aztec-nargo compile` again after changes

## 🎓 Epilogue: What You've Learned

Congratulations! You've just built a contract that:
- 🎭 Maintains complete privacy for individual users
- 🌍 Provides public accountability through the total counter
- 🔐 Implements access control (only owner can increment others)
- 🧪 Tests private state using utility functions

This pattern - private individual state with public aggregates - is powerful for:
- Voting systems
- Gaming scores
- Token balances
- Reputation systems
- And much more!

## 📚 Further Reading

Ready to dive deeper?
- [Aztec Smart Contracts Guide](https://docs.aztec.network/developers/guides/smart_contracts) - The complete documentation
- [Migration Notes](https://docs.aztec.network/migration_notes) - What's new in the latest version
- [Aztec Starter](https://github.com/AztecProtocol/aztec-starter#readme) - More example projects

## 🎮 Interactive Playground

Ready to experiment hands-on with the Counter contract? We've built an interactive playground where you can:

- **Deploy & Test**: Deploy the default Counter contract or upload your own modified version
- **Experience Privacy**: Switch between Alice, Bob, and Owner to see privacy in action
- **Real-time Interaction**: Increment counters and see zero-knowledge proofs being generated
- **Learn by Doing**: Understand how private state works through direct experimentation

**🚀 [Try the Counter Contract Playground](https://aztec-private-playground-59.lovable.app/)**

The playground connects to your local Aztec sandbox and lets you interact with the exact contract you just learned about. Perfect for:
- Testing contract modifications
- Understanding user privacy isolation  
- Seeing zero-knowledge proofs in action
- Experimenting with different scenarios

### Using Your Own Contract

1. Make modifications to the Counter contract in `src/main.nr`
2. Generate new artifacts: `aztec codegen -o src/artifacts target` 
3. Upload the generated `counter-Counter.json` file in the playground
4. Deploy and test your changes instantly!

---

*Now go build amazing things with your newfound knowledge of private state! The combination of privacy and transparency opens up entirely new design patterns. Happy coding! 🚀*