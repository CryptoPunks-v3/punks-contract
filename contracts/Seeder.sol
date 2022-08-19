pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol"
import "./interfaces/IPunksDescriptor.sol";
import "./interfaces/ISeeder.sol";

contract Seeder is ISeeder, Ownable {
    
    uint24[] cTypeProbability;
    mapping(uint16 => uint24[]) cSkinProbability;
    uint24[] cAccProbability;
    
    constructor() {
    }

    modifier onlyValidProbability {
        _;
        require(cumulative == 100000, "Probability must be summed up 100000 ( 100.000% x1000 )");
    }

    function generateSeed(uint punkId) external view returns (Seed memory ) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), punkId))
        );

        Seed seed = new Seed();

        uint24 partRandom = uint24(pseudorandomness)
        for(uint16 i = 0; i < cTypeProbability.length; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.punkType = i
                break;
            }
        }
        
        partRandom = uint24(pseudorandomness >> 24)
        for(uint16 i = 0; i < cTypeProbability.length; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.skinTone = i
                break;
            }
        }

        partRandom = uint24(pseudorandomness >> 48)
        for(uint16 i = 0; i < cAccProbability.length; i ++) {
            if(partRandom < cAccProbability[i]) {
                // set seed values here
                break;
            }
        }
        return seed;
    }

    function setTypeProbability(uint256[] calldata probabilities) external onlyOwner onlyValidProbability {
        _setProbability(cTypeProbability, probabilities)
    }
    function setSkinProbability(uint16 punkType, uint256[] calldata probabilities) external onlyOwner onlyValidProbability {
        _setProbability(cSkinProbability[punkType], probabilities)
    }
    function setAccProbability(uint256[] calldata probabilities) external onlyOwner onlyValidProbability {
        _setProbability(cAccProbability, probabilities)
    }
    
    function _setProbability(uint256[] storage cumulativeArray, uint256[] calldata probabilities) internal {
        delete cumulativeArray;
        uint256 cumulative = 0;
        for(uint256 i = 0; i < probabilities.length; i ++) {
            cumulative += probabilities[0];
            cumulativeArray.push(cumulative * 0xffffff / 100000);
        }
    }
}