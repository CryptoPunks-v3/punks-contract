pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPunksDescriptor.sol";
import "./interfaces/ISeeder.sol";

contract NSeeder is ISeeder, Ownable {
    
    // MAX_GROUP_COUNT = 16
    uint24[] public cTypeProbability;
    uint24[][] public cSkinProbability;
    uint24[] public cAccCountProbability;
    uint256[] public accFlags;
    uint256 accTypeCount;
    mapping(uint256 => uint256) public accExclusiveGroupMapping; // i: acc index, group index
    uint256[][] accExclusiveGroup; // i: group id, j: acc index in a group

    IPunksDescriptor public punkDescriptor;
    
    constructor(IPunksDescriptor descriptor) {
        punkDescriptor = descriptor;
    }

    function generateSeed(uint punkId) external view returns (Seed memory ) {
        uint256 pseudorandomness = uint256(
            keccak256(abi.encodePacked(blockhash(block.number - 1), punkId))
        );

        Seed memory seed;
        uint256 tmp;

        // Pick up random punk type
        uint24 partRandom = uint24(pseudorandomness);
        tmp = uint256(cTypeProbability.length);
        for(uint16 i = 0; i < tmp; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.punkType = i;
                break;
            }
        }
        
        // Pick up random skin tone
        partRandom = uint24(pseudorandomness >> 24);
        tmp = cSkinProbability.length;
        for(uint16 i = 0; i < tmp; i ++) {
            if(partRandom < cTypeProbability[i]) {
                seed.skinTone = i;
                break;
            }
        }

        // Get possible groups for the current punk type
        uint16 punkFlags = uint16(accFlags[seed.punkType]);
        uint256[] memory usedGroupFlags = new uint256[](accExclusiveGroup.length);
        uint256[] memory availableGroups = new uint256[](accExclusiveGroup.length);
        uint256 availableGroupCount = 0;
        for(uint8 acc = 0; punkFlags > 0; acc ++) {
            if(punkFlags & 0x01 == 1) {
                uint256 group = accExclusiveGroupMapping[acc];
                if(usedGroupFlags[group] == 0) {
                    availableGroups[availableGroupCount ++] = group;
                    usedGroupFlags[group] = 1;
                }
            }
            punkFlags >>= 1;
        }

        // Pick up random accessory count
        partRandom = uint24(pseudorandomness >> 48);
        uint16 curAccCount = 0;
        tmp = cAccCountProbability.length;
        for(uint16 i = 0; i < tmp; i ++) {
            if(partRandom * 0xffffff / cAccCountProbability[availableGroupCount] < cAccCountProbability[i]) {
                curAccCount = i;
                break;
            }
        }

        // Select current acc groups randomly
        pseudorandomness >>= 72;
        uint256[] memory selectedGroups = new uint256[](availableGroupCount);
        for(uint16 i = 0; i < availableGroupCount; i ++)
            selectedGroups[i] = i;
        for(uint16 i = 0; i < curAccCount; i ++) {
            uint16 tmpIndex = uint16((pseudorandomness >> (i * 8)) % availableGroupCount);
            tmp = selectedGroups[i];
            selectedGroups[i] = selectedGroups[tmpIndex];
            selectedGroups[tmpIndex] = tmp;
        }

        // Pick up random accessories as seed
        pseudorandomness >>= curAccCount * 8;
        seed.accessories = new Accessory[](curAccCount);
        for(uint16 i = 0; i < curAccCount; i ++) {
            uint256 group = availableGroups[selectedGroups[i]];
            uint accRand = pseudorandomness >> (i * 16);
            uint accInGroup = uint256(accRand & 0xff) % accExclusiveGroup[group].length;
            uint accType = accExclusiveGroup[group][accInGroup];
            
            seed.accessories[i] = Accessory({
                accType: uint16(accType),
                accId: uint16(punkDescriptor.accCountByType(accType) % (accRand >> 8))
            });
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
    function setAccCountProbability(uint256[] calldata probabilities) external onlyOwner {
        delete cAccCountProbability;
        _setProbability(cAccCountProbability, probabilities);
    }

    function setAccAvailability(uint256 count, uint256[] calldata flags) external onlyOwner {
        // i = 0;1;2;3;4
        delete accFlags;
        for(uint256 i = 0; i < flags.length; i ++)
            accFlags.push(flags[i]);
        accTypeCount = count;
    }

    // group list
    // key: group, value: accessory type
    function setExclusiveAcc(uint256 groupCount, uint256[] calldata exclusives) external onlyOwner {
        delete accExclusiveGroup;
        for(uint256 i = 0; i < groupCount; i ++)
            accExclusiveGroup.push();
        for(uint256 i = 0; i < accTypeCount; i ++) {
            accExclusiveGroupMapping[i] = exclusives[i];
            accExclusiveGroup[exclusives[i]].push(i);
        }
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