// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20, IRouterClient, EVM2AnyMessage, EVMTokenAmount} from "./Interfaces.sol";

/// @notice Deployed on Chain A (e.g. Arbitrum Sepolia).
/// Accepts token deposits and forwards a CCIP message to DestinationVault on Chain B.
contract SourceVault {
    address public immutable owner;
    IRouterClient public immutable router;
    address public immutable link;          // LINK token used to pay CCIP fees
    address public immutable token;         // ERC-20 being deposited
    uint64  public immutable destChain;     // CCIP chain selector for destination
    address public immutable destVault;     // DestinationVault address on Chain B

    event DepositSent(address indexed user, uint256 amount, bytes32 messageId);

    constructor(
        address _router,
        address _link,
        address _token,
        uint64  _destChain,
        address _destVault
    ) {
        owner     = msg.sender;
        router    = IRouterClient(_router);
        link      = _link;
        token     = _token;
        destChain = _destChain;
        destVault = _destVault;
    }

    /// @notice User deposits `amount` tokens. Contract forwards the intent to Chain B via CCIP.
    function deposit(uint256 amount) external {
        require(amount > 0, "Zero amount");
        IERC20(token).transferFrom(msg.sender, address(this), amount);

        // ponytail: tokens stay locked on Chain A; DestinationVault only records credit.
        // Actual token bridging requires CCIP token pool registration - out of scope here.
        EVM2AnyMessage memory message = EVM2AnyMessage({
            receiver:     abi.encode(destVault),
            data:         abi.encode(msg.sender, amount),
            tokenAmounts: new EVMTokenAmount[](0),
            feeToken:     link,
            extraArgs:    ""
        });

        uint256 fee = router.getFee(destChain, message);
        IERC20(link).approve(address(router), fee);

        bytes32 messageId = router.ccipSend(destChain, message);
        emit DepositSent(msg.sender, amount, messageId);
    }

    /// @notice Emergency withdraw - owner only.
    function withdrawToken(address tkn) external {
        require(msg.sender == owner, "Only owner");
        uint256 bal = IERC20(tkn).balanceOf(address(this));
        IERC20(tkn).transfer(owner, bal);
    }
}
