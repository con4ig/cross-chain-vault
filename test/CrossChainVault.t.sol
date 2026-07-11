// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SourceVault} from "../src/SourceVault.sol";
import {DestinationVault} from "../src/DestinationVault.sol";
import {Any2EVMMessage, EVMTokenAmount, EVM2AnyMessage, IRouterClient, IERC20} from "../src/Interfaces.sol";

/// @notice Tests use mock addresses — no fork needed.
/// CCIP Router calls are intercepted with vm.mockCall.
contract CrossChainVaultTest is Test {
    SourceVault      source;
    DestinationVault dest;

    address constant ROUTER  = address(0xBEEF);
    address constant LINK    = address(0xBEEF2);
    address constant TOKEN   = address(0xBEEF3);
    address constant USER    = address(0xABC);
    uint64  constant SRC_SEL = 111;
    uint64  constant DST_SEL = 222;
    uint256 constant AMOUNT  = 1000e18;
    uint256 constant CCIP_FEE = 1e18; // 1 LINK fee

    function setUp() public {
        source = new SourceVault(ROUTER, LINK, TOKEN, DST_SEL, address(0)); // dest addr set after
        dest   = new DestinationVault(ROUTER, address(source), SRC_SEL);

        // Stub getFee
        vm.mockCall(ROUTER,
            abi.encodeWithSelector(IRouterClient.getFee.selector),
            abi.encode(CCIP_FEE));

        // Stub ccipSend — returns a fake messageId
        vm.mockCall(ROUTER,
            abi.encodeWithSelector(IRouterClient.ccipSend.selector),
            abi.encode(bytes32("MSG_ID")));

        // Stub ERC20 calls (token and LINK)
        vm.mockCall(TOKEN, abi.encodeWithSelector(IERC20.transferFrom.selector), abi.encode(true));
        vm.mockCall(LINK,  abi.encodeWithSelector(IERC20.approve.selector),      abi.encode(true));
    }

    function testDepositEmitsEvent() public {
        vm.expectEmit(true, false, false, true);
        emit SourceVault.DepositSent(USER, AMOUNT, bytes32("MSG_ID"));

        vm.prank(USER);
        source.deposit(AMOUNT);
    }

    function testDepositRevertsOnZero() public {
        vm.prank(USER);
        vm.expectRevert("Zero amount");
        source.deposit(0);
    }

    function testCcipReceiveCreditUser() public {
        // Build a realistic Any2EVMMessage
        Any2EVMMessage memory msg_ = Any2EVMMessage({
            messageId:           bytes32("MSG_ID"),
            sourceChainSelector: SRC_SEL,
            sender:              abi.encode(address(source)),
            data:                abi.encode(USER, AMOUNT),
            destTokenAmounts:    new EVMTokenAmount[](0)
        });

        vm.prank(ROUTER);
        dest.ccipReceive(msg_);

        assertEq(dest.balances(USER), AMOUNT);
    }

    function testCcipReceiveRejectsWrongRouter() public {
        Any2EVMMessage memory msg_ = Any2EVMMessage({
            messageId:           bytes32("X"),
            sourceChainSelector: SRC_SEL,
            sender:              abi.encode(address(source)),
            data:                abi.encode(USER, AMOUNT),
            destTokenAmounts:    new EVMTokenAmount[](0)
        });

        vm.expectRevert("Only router");
        dest.ccipReceive(msg_); // called by address(this), not ROUTER
    }
}
