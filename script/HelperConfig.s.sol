// SPDX-License-Identifier: MIT

// 1. deploy mocks when we are on local anvil chain
// 2. keep track of contract addresses for different chains

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //If we are on a local anvil, we deploy mocks
    // else, grab the existing address from the live network.

    NetworkConfig public activeNetworkConfig;

    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    struct NetworkConfig{
        address priceFeed; //ETH/USD price feed address
    }

    constructor() {
        if (block.chainid == 11155111) {// chain ID of sepolia
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) { // chain ID of mainnet
            activeNetworkConfig = getMainnetEthConfig();
        }
        else {
            activeNetworkConfig = getOrCreateAnvilConfig();
        }
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) { // what was pure? 
        // price feed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
            });
            return ethConfig;
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) { // what was pure? 
        // price feed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
            });
            return sepoliaConfig;
    }

    function getOrCreateAnvilConfig() public returns (NetworkConfig memory) { 
        
        if(activeNetworkConfig.priceFeed != address(0)) { // if its not the default address, we have already set it.
            return activeNetworkConfig;
        }

        //1. deploy mock contracts
        //2. return mock address

        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE); // eth has 8 decimals
        vm.stopBroadcast();

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mockPriceFeed)
            });
            return anvilConfig;
    }
}