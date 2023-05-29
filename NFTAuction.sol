// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import "./AuctionPriceConverter.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NFTAuction {
    using AuctionPriceConverter for uint256;

    address public immutable owner;
    uint256 public immutable minimumContributionUSD;
    IERC721 public NFT;
    uint256 tokenId;
    address[] public bidders;
    mapping(address => uint256) bidderToAmount;


    constructor(address _tokenAddress, uint256 _tokenId, uint256 _minimumContributionUSD) {
        owner = msg.sender;
        minimumContributionUSD = _minimumContributionUSD;
        NFT = IERC721(_tokenAddress);
        tokenId = _tokenId;
    }

    function makeBid() external payable {
        require(msg.value.getConversionRate() >= minimumContributionUSD, "You did not send enough USD to make a bid");
        bidders.push(msg.sender);
        bidderToAmount[msg.sender] += msg.value;
    }

    function finalizeMarket() external onlyOwner {
        uint256 max;
        address winnerAddress;
        for (uint i=0; i < bidders.length; i++) {
            address candidate = bidders[i];
            if (bidderToAmount[candidate]>max) {
                max = bidderToAmount[candidate];
                winnerAddress = candidate;
            } else {
                payable(candidate).transfer(bidderToAmount[candidate]);
            }
        }

        payable(owner).transfer(max);
        NFT.safeTransferFrom(owner, winnerAddress, tokenId);
    }

    function revertMarket() external onlyOwner {
        for (uint i=0; i < bidders.length; i++) {
            address candidate = bidders[i];
            payable(candidate).transfer(bidderToAmount[candidate]);
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}