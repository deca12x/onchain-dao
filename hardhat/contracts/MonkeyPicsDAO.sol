// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);

    function purchase(uint256 _tokenId) external payable;
}

interface IMonkeyPicsNFT {
    function balanceOf(address owner) external view returns (uint256);

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) external view returns (uint256);
}

contract MonkeyPicsDAO is Ownable {
    struct Proposal {
        uint256 nftTokenId;
        uint256 deadline;
        uint256 yVotes;
        uint256 nVotes;
        bool executed;
        mapping(uint256 => bool) tokenIdToVoted;
    }

    mapping(uint256 => Proposal) public tokenIdToProposals;
    uint256 public numProposalsCreated;

    IFakeNFTMarketplace nftMarketplace;
    IMonkeyPicsNFT monkeyPicsNFT;

    constructor(address _nftMarketplace, address _monkeyPicsNFT) payable {
        nftMarketplace = IFakeNFTMarketplace(_nftMarketplace);
        monkeyPicsNFT = IMonkeyPicsNFT(_monkeyPicsNFT);
    }

    modifier nftHolderOnly() {
        require(monkeyPicsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    function createProposal(
        uint256 _nftTokenId
    ) external nftHolderOnly returns (uint256) {
        require(nftMarketplace.available(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = tokenIdToProposals[numProposalsCreated];
        proposal.nftTokenId = _nftTokenId;
        proposal.deadline = block.timestamp + 5 minutes;
        numProposalsCreated++;
        return numProposalsCreated - 1;
    }
}
