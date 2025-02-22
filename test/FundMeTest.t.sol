// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); //static, not cool
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), msg.sender); 
        // prior to refactor: msg.sender wont work, because fundMe variable is created by FundMeTest
        // upToDate: msg.sender will work, because fundMe is created by DeployFundMe
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughEth() public{
        vm.expectRevert(); // means next line shoul revert / it fails
        fundMe.fund(); // sending 0 value.
    }

    function testFundUpdatesFundedDataStructure() public {
        fundMe.fund{value: 10e18}();

        uint256 amoundFunded = fundMe.getAddressToAmountFunded(msg.sender);
        assertEq(amoundFunded, 10e18);
    }


}

//  4 types of tests
//* **Unit tests**: Focus on isolating and testing individual smart contract functions or functionalities.
//* **Integration tests**: Verify how a smart contract interacts with other contracts or external systems.
//* **Forking tests**: Forking refers to creating a copy of a blockchain state at a specific point in time. This copy, called a fork, is then used to run tests in a simulated environment.
//* **Staging tests**: Execute tests against a deployed smart contract on a staging environment before mainnet deployment.


// for testing: forge test -vvv --fork-url $SEPOLIA_RPC 
// for testing one single test: -m testPriceFeedVersionIsAccurate