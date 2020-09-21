
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import './Product.sol';
import './Tender.sol';


contract VendorContract {

    struct Vendor {
        address vendor;
        bytes32[] products;
        bytes32[] tenderIds;
        bool exists;
    }
    
    address[] internal vendorsList;
    mapping(address => Vendor) internal vendors;
    
    function getVendor(address _vendor) public view returns (Vendor memory) {
        return vendors[_vendor];
    }
    
    function getVendorList() public virtual view returns (address[] memory) {
        return vendorsList;
    }
}


