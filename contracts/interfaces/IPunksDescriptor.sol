pragma solidity ^0.8.15;

interface IPunksDescriptor {
    ///
    /// USED BY SEEDER
    ///

    function accCountByType(uint256 accType) external view returns (uint256);
}