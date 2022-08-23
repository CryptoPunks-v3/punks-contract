pragma solidity ^0.8.15;

interface ISeeder {
    struct Seed {
        uint16 punkType;
        uint16 skinTone;
        uint16 nose;
        uint16 eyes;
        uint16 mouth;
        uint16 hair;
        uint16 ears;
        uint16 teeth;
        uint16 lips;
        uint16 emotion;
        uint16 beard;
        uint16 cheeks;
        uint16 face;
        uint16 neck;
    }

    function generateSeed(uint256 punkId) external view returns (Seed memory);
}