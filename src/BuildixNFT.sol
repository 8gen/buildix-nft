// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {IERC721A, ERC721A} from "erc721a/ERC721A.sol";
import {ERC721AQueryable} from "erc721a/extensions/ERC721AQueryable.sol";
import {ERC721ABurnable} from "erc721a/extensions/ERC721ABurnable.sol";
import {OperatorFilterer} from "./OperatorFilterer.sol";
import {Ownable} from "@oz/access/Ownable.sol";
import {IERC2981, ERC2981} from "@oz/token/common/ERC2981.sol";
import {IERC20} from "@oz/token/ERC20/IERC20.sol";


contract BuildixNFT is
    ERC721AQueryable,
    ERC721ABurnable,
    OperatorFilterer,
    Ownable,
    ERC2981
{
    bool public operatorFilteringEnabled;
    uint256 public mintPrice;
    string public baseURI;
    uint256 public maxSupply;
    address public treasure;

    constructor() ERC721A("Buildix NFT", "BUILDIX") {
        // init operator filter
        _registerForOperatorFiltering();
        operatorFilteringEnabled = true;
        _setDefaultRoyalty(msg.sender, 500);

        // pre-mint
        _mint(msg.sender, 24);

        // init
        mintPrice = 1 ether;
        treasure = msg.sender;
        maxSupply = 50;
    }

    // ======= ADMIN FUNCTIONS ======
    // @dev set mint price, owner may change price during minting 
    function setMintPrice(uint256 _price) public onlyOwner {
        // fat-finger check
        require(_price > 0.00001 ether, "BuildixNFT: invalid price");
        mintPrice = _price;
    }

    // @dev set treasure
    function setTreasure(address _treasure) public onlyOwner {
        require(_treasure != address(0), "BuildixNFT: invalid address");
        treasure = _treasure;
    }

    // @dev set baseuri, necessary for future reveal
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        require(bytes(_newBaseURI).length > 0, "BuildixNFT: invalid baseURI");
        baseURI = _newBaseURI;
    }

    // @dev withdraw ETH, necessary when somebody sent by mistake native tokens to this contract
    function withdraw() public onlyOwner {
        address payable owner = payable(msg.sender);
        owner.transfer(address(this).balance);
    }

    // @dev withdraw ERC20, necessary when somebody sent by mistake tokens to this contract
    function withdrawToken(address _token) public onlyOwner {
        IERC20(_token).transfer(msg.sender, address(this).balance);
    }

    // ======= MINT FUNCTIONS =====
    // @dev paid mint, anyone can mint, but only 1 token and until max supply is reached
    function mint(address to) public payable {
        require(to != address(0), "BuildixNFT: invalid address");
        require(msg.value == mintPrice, "BuildixNFT: insufficient payment");
        require(maxSupply > totalSupply(), "BuildixNFT: max supply reached");
        _mint(to, 1);
        payable(treasure).transfer(address(this).balance);
    }

    // ======= TOKEN FUNCTIONS =====
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override(ERC721A, IERC721A) returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory prefix = _baseURI();
        return bytes(prefix).length != 0 ? string(abi.encodePacked(prefix, _toString(tokenId), ".json")) : '';
    }

    // ======= OPERATOR FILTER FUNCTIONS =====
    function setApprovalForAll(address operator, bool approved)
        public
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        payable
        override(IERC721A, ERC721A)
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC721A, ERC721A, ERC2981)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || ERC2981.supportsInterface(interfaceId);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator) public onlyOwner {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function setOperatorFilteringEnabled(bool value) public onlyOwner {
        operatorFilteringEnabled = value;
    }

    function _operatorFilteringEnabled() internal view override returns (bool) {
        return operatorFilteringEnabled;
    }

    function _isPriorityOperator(address operator) internal pure override returns (bool) {
        return operator == address(0x1E0049783F008A0085193E00003D00cd54003c71);
    }
}
