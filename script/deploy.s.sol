// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/BuildixNFT.sol";

contract DeployScript is Script {
    function setUp() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        BuildixNFT nft = new BuildixNFT();
        nft.setBaseURI("ipfs://QmRPSubNW7AiKqEWQRHvdEq6m9qYFzddxEXSqMqS4AZJFj/");
        vm.stopBroadcast();
    }

    function run() public {
        vm.broadcast();
    }
}
