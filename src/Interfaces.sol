// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
    function approve(address, uint256) external returns (bool);
}

// Chainlink CCIP — minimal surface needed to send and receive messages
struct EVMTokenAmount {
    address token;
    uint256 amount;
}

struct EVM2AnyMessage {
    bytes receiver;         // abi.encode(address) of receiver on dest chain
    bytes data;             // arbitrary payload
    EVMTokenAmount[] tokenAmounts;
    address feeToken;       // address(0) = pay in native
    bytes extraArgs;        // encode gas limit with Client.argsToBytes
}

struct Any2EVMMessage {
    bytes32 messageId;
    uint64  sourceChainSelector;
    bytes   sender;
    bytes   data;
    EVMTokenAmount[] destTokenAmounts;
}

interface IRouterClient {
    function getFee(uint64 destChainSelector, EVM2AnyMessage memory message)
        external view returns (uint256);
    function ccipSend(uint64 destChainSelector, EVM2AnyMessage memory message)
        external payable returns (bytes32 messageId);
}

interface CCIPReceiver {
    function ccipReceive(Any2EVMMessage calldata message) external;
}
