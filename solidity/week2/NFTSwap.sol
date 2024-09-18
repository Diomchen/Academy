// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTSwap is ReentrancyGuard {
    struct Order {
        address owner;
        uint256 price;
    }

    // Mapping from NFT contract address to tokenId to Order
    mapping(address => mapping(uint256 => Order)) public orders;

    event Listed(address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event Revoked(address indexed nftContract, uint256 indexed tokenId);
    event Updated(address indexed nftContract, uint256 indexed tokenId, uint256 newPrice);
    event Purchased(address indexed nftContract, uint256 indexed tokenId, address indexed buyer);

    // List an NFT for sale
    function list(address nftContract, uint256 tokenId, uint256 price) external nonReentrant {
        require(price > 0, "Price must be greater than zero");
        IERC721 nft = IERC721(nftContract);
        require(nft.ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        require(nft.getApproved(tokenId) == address(this) || nft.isApprovedForAll(msg.sender, address(this)), "Contract not approved to transfer NFT");

        orders[nftContract][tokenId] = Order(msg.sender, price);
        emit Listed(nftContract, tokenId, price);
    }

    // Revoke an order
    function revoke(address nftContract, uint256 tokenId) external nonReentrant {
        Order storage order = orders[nftContract][tokenId];
        require(order.owner == msg.sender, "You are not the owner of this order");

        delete orders[nftContract][tokenId];
        emit Revoked(nftContract, tokenId);
    }

    // Update the price of an order
    function update(address nftContract, uint256 tokenId, uint256 newPrice) external nonReentrant {
        require(newPrice > 0, "Price must be greater than zero");
        Order storage order = orders[nftContract][tokenId];
        require(order.owner == msg.sender, "You are not the owner of this order");

        order.price = newPrice;
        emit Updated(nftContract, tokenId, newPrice);
    }

    // Purchase an NFT
    function purchase(address nftContract, uint256 tokenId) external payable nonReentrant {
        Order storage order = orders[nftContract][tokenId];
        require(order.owner != address(0), "Order does not exist");
        require(msg.value == order.price, "Incorrect payment amount");

        IERC721 nft = IERC721(nftContract);
        address seller = order.owner;

        // Transfer NFT to buyer
        nft.safeTransferFrom(seller, msg.sender, tokenId);

        // Transfer payment to seller
        payable(seller).transfer(msg.value);

        // Clear the order
        delete orders[nftContract][tokenId];

        emit Purchased(nftContract, tokenId, msg.sender);
    }
}