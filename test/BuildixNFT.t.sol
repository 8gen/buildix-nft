// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {BuildixNFT} from "../src/BuildixNFT.sol";


contract BuildixNFTTest is Test {
    BuildixNFT public nft;
    address public owner = address(1);
    address public buyer = address(2);
    address public newOwner = address(3);
    address public treasure = 0x77c218De73001779301FC76ffa8f93568C75fdb0;

    uint256 forkId;

    function setUp() public {

        // try to run over real network
        string memory RPC_URL = vm.envString("RPC_URL");
        forkId = vm.createSelectFork(RPC_URL);
        vm.startPrank(owner);
        nft = new BuildixNFT();
        assertEq(nft.owner(), owner);
        deal(owner, 1000 ether);
        deal(buyer, 1000 ether);
        nft.setBaseURI("ipfs://hidden/");
        nft.setTreasure(treasure);
        vm.stopPrank();
    }

    function test_check_initial_balance() public {
        assertEq(nft.balanceOf(treasure), 30);
        vm.prank(treasure);
        nft.transferFrom(treasure, buyer, 1);
        assertEq(nft.balanceOf(treasure), 29);
        assertEq(nft.balanceOf(buyer), 1);
        assertEq(nft.totalSupply(), 30);
    }

    function test_mint_in_supply() public {
        uint256 price = nft.mintPrice();
        uint256 treasureBalance = treasure.balance;
        // call method with 1 ether
        vm.prank(buyer);
        nft.mint{value: price}(buyer);
        assertEq(nft.balanceOf(buyer), 1);
        assertEq(nft.totalSupply(), 31);
        assertEq(treasure.balance - price, treasureBalance);
    }

    function test_check_reveal() public {
        vm.startPrank(owner);
        assertEq(nft.tokenURI(1), "ipfs://hidden/1.json");
        nft.setBaseURI("ipfs://revealed/");
        assertEq(nft.tokenURI(1), "ipfs://revealed/1.json");
    }

    function test_mints_until_max() public {
        uint256 price = nft.mintPrice();
        vm.startPrank(buyer);
        for(uint256 i = 0; i < 20; i++) {
            nft.mint{value: price}(buyer);
        }
        assertEq(nft.balanceOf(buyer), 20);
        assertEq(nft.totalSupply(), 50);
        assertEq(nft.tokenURI(50), "ipfs://hidden/50.json");

        // should revert on limit over max supply
        vm.expectRevert("BuildixNFT: max supply reached");
        nft.mint{value: price}(buyer);
    }

    function test_mint_with_lower_amout() public {
        vm.startPrank(buyer);
        uint256 price = nft.mintPrice();
        vm.expectRevert("BuildixNFT: insufficient payment");
        nft.mint{value: price - 1}(buyer);
    }

    function test_set_price() public {
        uint256 price = nft.mintPrice();
        vm.prank(owner);
        nft.setMintPrice(price * 2);
        assertEq(nft.mintPrice(), price * 2);

        // try to set price from wrong user
        vm.startPrank(buyer);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.setMintPrice(price * 3);
    }

    function test_transfer_ownership() public {
        assertEq(nft.owner(), owner);
        vm.prank(owner);
        nft.transferOwnership(newOwner);
        assertEq(nft.owner(), newOwner);
        uint256 price = nft.mintPrice();
        vm.prank(newOwner);
        nft.setMintPrice(price * 2);
    }
}
