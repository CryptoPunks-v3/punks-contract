pragma solidity ^0.8.15;

import "hardhat/console.sol";
import './NSeeder.sol';
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NToken is Ownable {
    NSeeder seeder;
    mapping(bytes32 => uint) seedHashes;

    constructor(
        NSeeder _seeder
    ) {
        seeder = _seeder;
    }

    function _mint(address to, uint256 tokenId) internal {
        NSeeder.Seed memory seed = seeder.generateSeed(tokenId);
        
        bytes32 seedHash;
        assembly {
            let accLen := mload(seed)
            seedHash := keccak256(seed, add(0x60, mul(accLen, 0x40)))
        }
        seedHashes[seedHash] = 1;
    }
    function mint(address to, uint256 tokenId) external onlyOwner {
        _mint(to, tokenId);
    }
    function registerOGHashes(bytes32[] calldata hashes) external onlyOwner {
        for(uint i = 0; i < hashes.length; i ++) {
            seedHashes[hashes[i]] = 1;
        }
    }
}