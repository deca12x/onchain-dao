// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IFakeNFTMarketplace {
    function purchase(uint256 _tokenId) external payable;

    function getPrice() external view returns (uint256);

    function available(uint256 _tokenId) external view returns (bool);
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

    modifier activeProposalOnly(uint256 proposalIndex) {
        require(
            tokenIdToProposals[proposalIndex].deadline > block.timestamp,
            "DEADLINE_EXCEEDED"
        );
        _;
    }

    enum Vote {
        Y, // Y = 0
        N // N = 1
    }

    function voteOnProposal(
        uint256 proposalIndex,
        Vote vote
    ) external nftHolderOnly activeProposalOnly(proposalIndex) {
        Proposal storage proposal = tokenIdToProposals[proposalIndex];

        uint256 voterNFTBalance = monkeyPicsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = monkeyPicsNFT.tokenOfOwnerByIndex(msg.sender, i);
            if (proposal.tokenIdToVoted[tokenId] == false) {
                numVotes++;
                proposal.tokenIdToVoted[tokenId] = true;
            }
        }
        require(numVotes > 0, "ALREADY_VOTED");

        if (vote == Vote.Y) {
            proposal.yVotes += numVotes;
        } else {
            proposal.nVotes += numVotes;
        }
    }

    modifier inactiveProposalOnly(uint256 proposalIndex) {
        require(
            tokenIdToProposals[proposalIndex].deadline <= block.timestamp,
            "DEADLINE_NOT_EXCEEDED"
        );
        require(
            tokenIdToProposals[proposalIndex].executed == false,
            "PROPOSAL_ALREADY_EXECUTED"
        );
        _;
    }

    // any NFT holder can execute a proposal after it's deadline
    function executeProposal(
        uint256 proposalIndex
    ) external nftHolderOnly inactiveProposalOnly(proposalIndex) {
        Proposal storage proposal = tokenIdToProposals[proposalIndex];

        // If the proposal passes, purchase the NFT from the FakeNFTMarketplace
        if (proposal.yVotes > proposal.nVotes) {
            uint256 nftPrice = nftMarketplace.getPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            nftMarketplace.purchase{value: nftPrice}(proposal.nftTokenId);
        }
        proposal.executed = true;
    }

    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "Nothing to withdraw, contract balance empty");
        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    // The following 2 functions allow the contract to accept ETH deposit directly from a wallet without calling a function
    receive() external payable {}

    fallback() external payable {}
}
