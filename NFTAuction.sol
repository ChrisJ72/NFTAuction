// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

contract NFTAuction {
    address public immutable owner;
    uint256 public immutable minimumContribution;
    address[] public bidders;
    mapping(address => uint256) bidderToAmount;


    constructor(uint256 _minimumContribution) {
        owner = msg.sender;
        minimumContribution = _minimumContribution;
    }

    function makeBid() public payable {
        bidders.push(msg.sender);
        bidderToAmount[msg.sender] += msg.value;
    }

    function finalizeMarket() public onlyOwner {
        uint256 max;
        address winnerAddress;
        for (uint i=0; i < bidders.length; i++) {
            address candidate = bidders[i];
            if (bidderToAmount[candidate]>max) {
                max = bidderToAmount[candidate];
                winnerAddress = candidate;
            }
        }
        (bool callSuccess,) = payable(winnerAddress).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    function revertMarket() public onlyOwner {
        for (uint i=0; i < bidders.length; i++) {
            address candidate = bidders[i];
            (bool callSuccess,) = payable(candidate).call{value: bidderToAmount[candidate]}("");
            require(callSuccess, "Call failed");
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}