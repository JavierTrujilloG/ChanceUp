pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import './Tender.sol';

contract BuyerContract {
    
    struct Buyer {
        address buyer;
        bytes32[] tenderIds;
        bool exists;
    }
    
    address[] internal buyersList;
    mapping(address => Buyer) internal buyers;
    
    function getBuyer(address _buyer) public view returns (Buyer memory) {
        return buyers[_buyer];
    }
}
