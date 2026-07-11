# Cross Chain Yield Aggregator

This is a simple but advanced yield aggregator project that operates across different networks. The idea is that a user deposits funds on one network, for example Arbitrum, and we seamlessly use Chainlink CCIP in the background to send a message to another network, like Optimism, where those funds are credited to the user's account and can be put to work in local DeFi protocols.

The user does not need to worry about manually bridging tokens or holding gas tokens on the destination network. Our contract on the source network (SourceVault) collects the deposit and covers all CCIP messaging costs using LINK tokens, while the destination contract (DestinationVault) safely receives this message and updates balances. Everything operates on purely native functions and minimal interfaces without pulling in massive external libraries, adhering to the principles of clean, pragmatic code.

The project can be tested locally using Foundry, where tests simulate the operation of the CCIP router without needing to interact with external networks.

To run it and check the tests yourself, simply type forge test in the terminal and watch the entire mechanism work flawlessly. I also left a simple deployment script for both networks.
