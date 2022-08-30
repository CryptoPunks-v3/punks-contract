pragma solidity ^0.8.15;
import "../interfaces/IPunksDescriptor.sol";

contract PunksDescriptor is IPunksDescriptor {
    function accCountByType(uint256 accType) external view returns (uint256) {
        if(accType == 0) return 18;
        if(accType == 1) return 36;
        if(accType == 2) return 12;
        if(accType == 3) return 7;
        if(accType == 4) return 20;
        if(accType == 5) return 8;
        if(accType == 6) return 1;
        if(accType == 7) return 3;
        if(accType == 8) return 5;
        if(accType == 9) return 2;
        if(accType == 10) return 4;
        if(accType == 11) return 61;
        if(accType == 12) return 2;
        if(accType == 13) return 2;
        return 0;
    }
}

