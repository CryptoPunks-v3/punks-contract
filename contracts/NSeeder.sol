pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPunksDescriptor.sol";
import "./interfaces/ISeeder.sol";

contract NSeeder is ISeeder, Ownable {
    
    // MAX_GROUP_COUNT = 16
    uint24[] public cTypeProbability;
    uint24[][] public cSkinProbability;
    uint24[] public cAccProbability;
    uint256[] public accFlags;
    uint256 accCount;
    mapping(uint256 => uint256) public accGroupMapping; // i: acc index, group index
    uint256[][] accGroup; // i: group id, j: acc index in a group
    
    constructor() {
    }

    function generateSeed(uint punkId) external view returns (Seed memory ) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), punkId))
        );

        Seed memory seed;

        // Pick up random punk type
        uint24 partRandom = uint24(pseudorandomness);
        for(uint16 i = 0; i < cTypeProbability.length; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.punkType = i;
                break;
            }
        }
        
        // Pick up random skin tone
        partRandom = uint24(pseudorandomness >> 24);
        for(uint16 i = 0; i < cTypeProbability.length; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.skinTone = i;
                break;
            }
        }

        // Get possible groups for the current punk type
        uint16 punkFlags = uint16(accFlags[seed.punkType]);
        uint256[] memory usedGroupFlags = new uint256[](accGroup.length);
        uint256[] memory availableGroups = new uint256[](accGroup.length);
        uint256 availableGroupCount = 0;
        for(uint8 acc = 0; punkFlags > 0; acc ++) {
            if(punkFlags & 0x01 == 1) {
                uint256 group = accGroupMapping[acc];
                if(usedGroupFlags[group] == 1)
                    availableGroups[availableGroupCount ++] = group;
                else
                    usedGroupFlags[group] = 1;
            }
            punkFlags >>= 1;
        }

        // Pick up random accessory count
        partRandom = uint24(pseudorandomness >> 48);
        uint16 curAccCount = 0;
        for(uint16 i = 0; i < cAccProbability.length; i ++) {
            if(uint256(partRandom) * 0xffffff / cAccProbability[availableGroupCount] < cAccProbability[i]) {
                curAccCount = i;
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

    function setAccAvailability(uint256 count, uint256[] calldata flags) external onlyOwner {
        // i = 0;1;2;3;4
        for(uint i = 0; i < flags.length; i ++)
            accFlags[i] = flags[i];
        accCount = count;
    }
    function setExclusiveAcc(uint256[] calldata exclusives) external onlyOwner {
        
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