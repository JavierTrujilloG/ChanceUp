
pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

contract ProductContract {
    
    struct Product {
        string title;
        string description;
        uint256 price;
        bool exists;
    }
    
    bytes32[] productsList;
    mapping(bytes32 => Product) products;
    
    function createProduct(address vendor, string memory _title, string memory _description, uint256 _price) internal returns (bytes32){
        bytes32 productId = keccak256(abi.encode(vendor, _title));
        products[productId] = Product(_title, _description, _price, true);
        productsList.push(productId);
        return productId;
    }
    
    function getProduct(bytes32 productId) public view returns (Product memory) {
        return products[productId];
    }
}
