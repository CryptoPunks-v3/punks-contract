pragma solidity ^0.8.15;

interface ISeeder {
    struct Accessory {
        uint16 accType;
        uint16 accId;
    }
    struct Seed {
        uint16 punkType;
        uint16 skinTone;
        Accessory[] accessories;
    }

    function generateSeed(uint256 punkId) external view returns (Seed memory);
}