// SPDX-License-Identifier: MIT

// 1. deploy mocks when we are on local anvil chain
// 2. keep track of contract addresses for different chains

pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    //If we are on a local anvil, we deploy mocks
    // else, grab the existing address from the live network.

    NetworkConfig public activeNetworkConfig;

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
            activeNetworkConfig = getAnvilEthConfig();
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

    function getAnvilEthConfig() public pure returns (NetworkConfig memory) { 
        // price feed address
    }
}