// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Any2EVMMessage} from "./Interfaces.sol";

/// @notice Deployed on Chain B (e.g. Optimism Sepolia).
/// Receives CCIP messages from SourceVault and records user credits.
contract DestinationVault {
    address public immutable owner;
    address public immutable router;        // CCIP Router on this chain
    address public immutable sourceVault;   // Authorized SourceVault address on Chain A
    uint64  public immutable sourceChain;   // CCIP chain selector of Chain A

    // User credit balances (credited when CCIP message arrives)
    mapping(address => uint256) public balances;

    event CreditReceived(bytes32 indexed messageId, address indexed user, uint256 amount);

    constructor(address _router, address _sourceVault, uint64 _sourceChain) {
        owner       = msg.sender;
        router      = _router;
        sourceVault = _sourceVault;
        sourceChain = _sourceChain;
    }

    /// @dev Called by the CCIP Router when a cross-chain message arrives.
    function ccipReceive(Any2EVMMessage calldata message) external {
        require(msg.sender == router, "Only router");
        require(message.sourceChainSelector == sourceChain, "Wrong source chain");
        require(abi.decode(message.sender, (address)) == sourceVault, "Wrong sender");

        (address user, uint256 amount) = abi.decode(message.data, (address, uint256));
        balances[user] += amount;

        emit CreditReceived(message.messageId, user, amount);
    }
}
