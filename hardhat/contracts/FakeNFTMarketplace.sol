// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract FakeNFTMarketplace {
    mapping(uint256 => address) public monkeyOwnerAddresses;
    uint256 nftPrice = 0.1 ether;

    function purchase(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "All monkeys cost 0.1 ether");
        monkeyOwnerAddresses[_tokenId] = msg.sender;
    }

    function getPrice() external view returns (uint256) {
        return nftPrice;
    }

    function available(uint256 _tokenId) external view returns (bool) {
        if (monkeyOwnerAddresses[_tokenId] == address(0)) {
            return true;
        }
        return false;
    }
}
