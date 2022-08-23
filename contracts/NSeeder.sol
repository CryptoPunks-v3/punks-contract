pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPunksDescriptor.sol";
import "./interfaces/ISeeder.sol";

contract NSeeder is ISeeder, Ownable {
    
    uint24[] public cTypeProbability;
    uint24[][] public cSkinProbability;
    uint24[] public cAccProbability;
    
    constructor() {
    }

    function generateSeed(uint punkId) external view returns (Seed memory ) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), punkId))
        );

        Seed memory seed;

        uint24 partRandom = uint24(pseudorandomness);
        for(uint16 i = 0; i < cTypeProbability.length; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.punkType = i;
                break;
            }
        }
        
        partRandom = uint24(pseudorandomness >> 24);
        for(uint16 i = 0; i < cTypeProbability.length; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.skinTone = i;
                break;
            }
        }

        partRandom = uint24(pseudorandomness >> 48);
        for(uint16 i = 0; i < cAccProbability.length; i ++) {
            if(partRandom < cAccProbability[i]) {
                // set seed values here
                break;
            }
        }
        return seed;
    }

    function setTypeProbability(uint256[] calldata probabilities) external onlyOwner {
        delete cTypeProbability;
        _setProbability(cTypeProbability, probabilities);
    }
    function setSkinProbability(uint16 punkType, uint256[] calldata probabilities) external onlyOwner {
        while(cSkinProbability.length < punkType + 1)
            cSkinProbability.push(new uint24[](0));
        delete cSkinProbability[punkType];
        _setProbability(cSkinProbability[punkType], probabilities);
    }
    function setAccProbability(uint256[] calldata probabilities) external onlyOwner {
        delete cAccProbability;
        _setProbability(cAccProbability, probabilities);
    }
    
    function _setProbability(
        uint24[] storage cumulativeArray,
        uint256[] calldata probabilities
    ) internal {
        uint256 cumulative = 0;
        for(uint256 i = 0; i < probabilities.length; i ++) {
            cumulative += probabilities[i];
            cumulativeArray.push(uint24(cumulative * 0xffffff / 100000));
        }
        require(cumulative == 100000, "Probability must be summed up 100000 ( 100.000% x1000 )");
    }
}