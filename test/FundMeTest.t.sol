// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {

    FundMe fundMe;

    address USER = makeAddr("user");
    uint256 constant USER_INIT_BALANCE = 10 ether;
    uint256 constant SEND_VALUE = 0.1 ether; // 100000000000000000 wei
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); //static, not cool
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender); 
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

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amoundFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amoundFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded{
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() { // repeating test setup.
        vm.prank(USER); // the next transaction will be from USER
        vm.deal(USER, USER_INIT_BALANCE); // give user 10 eth
        fundMe.fund{value: SEND_VALUE}();  // sending 0.1 ether from USER
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert(); // next line (which includes a tx) should revert
        vm.prank(USER); // doesnt check the revert on this one.
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeContractBalance = address(fundMe).balance;

        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner()); // should have spent gas? 
        fundMe.withdraw();
        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(endingOwnerBalance, startingOwnerBalance + startingFundMeContractBalance);
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10; // addresses are 20 bytes long, so 160 bits
        uint160 startingFunderIndex = 1; // 0 address reverts sometimes, so we start from 1

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VALUE); // hoax is vm.prank & vm.deal combined
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeContractBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner()); // vm.broadcast + prank
        fundMe.withdraw(); 
        vm.stopPrank();

        // Assert
        assertEq(address(fundMe).balance, 0);
        assertEq(startingOwnerBalance + startingFundMeContractBalance, fundMe.getOwner().balance);
    }

    
}


//  4 types of tests
//* **Unit tests**: Focus on isolating and testing individual smart contract functions or functionalities.
//* **Integration tests**: Verify how a smart contract interacts with other contracts or external systems.
//* **Forking tests**: Forking refers to creating a copy of a blockchain state at a specific point in time. This copy, called a fork, is then used to run tests in a simulated environment.
//* **Staging tests**: Execute tests against a deployed smart contract on a staging environment before mainnet deployment.


// for testing: forge test -vvv --fork-url $SEPOLIA_RPC 
// for testing one single test: -m testPriceFeedVersionIsAccurate

//you can also use Chisel to sanity check code quickly ( solidity in your terminal )
// forge snapshot -- checks how much gas was used combined with --match-test <TEST_NAME>
// when working with anvil, gas price for tx defaults to 0