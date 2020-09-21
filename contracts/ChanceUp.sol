pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import './Vendor.sol';
import './Buyer.sol';
import './Tender.sol';
import './Product.sol';


contract ChanceUp is VendorContract, BuyerContract, TenderContract, ProductContract{
    using SafeMath for uint256;
    address private admin;
    
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    
    modifier isVendor() {
        require(vendors[msg.sender].exists, "Caller is not a vendor");
        _;
    }
    
    modifier isBuyer() {
        require(buyers[msg.sender].exists, "Caller is not a buyer");
        _;
    }
    
    constructor() public {
        admin = msg.sender;
    }
    
    mapping(address => bytes32[]) vendorToProducts;

    event AddVendor (address _vendorAddress);
    function addVendor(address _vendorAddress)
        public onlyAdmin {
         vendors[_vendorAddress].vendor = _vendorAddress;     
         vendors[_vendorAddress].exists = true;
         vendorsList.push(_vendorAddress);
         emit AddVendor(_vendorAddress);
    }
    
    function addBuyer(address _buyerAddress)
        public onlyAdmin {
         buyers[_buyerAddress].buyer = _buyerAddress;
         buyers[_buyerAddress].exists = true;
         buyersList.push(_buyerAddress);
    }
    
    function getProductList() public view returns (bytes32[] memory) {
        return productsList;
    } 
    
    function createProductForVendor(string memory _title, string memory _description, uint256 _price) public isVendor {
        bytes32 productId = ProductContract.createProduct(msg.sender, _title, _description, _price);
        Vendor storage vendor = vendors[msg.sender];
        vendor.products.push(productId);
    }
    
    function getProductsForVendor() public view isVendor returns (bytes32[] memory){
        Vendor storage vendor = vendors[msg.sender];
        return vendor.products;
    }
    
    
    
    function startTender(
        bytes32 productId,
        uint durationInDays
    ) isVendor external {
        bytes32[] memory vendorProducts = vendors[msg.sender].products;
        // TODO check that productId belongs to vendorProducts
        Product memory product = ProductContract.getProduct(productId);
        // TODO check for product existance
        bytes32 tenderId = TenderContract.createTender(payable(msg.sender), product, durationInDays);
        Vendor storage vendor = vendors[msg.sender];
        vendor.tenderIds.push(tenderId);
    }
    
    function getTendersForVendor() external view isVendor returns (
        bytes32[] memory,
        uint[] memory,
        uint256[] memory,
        uint [] memory,
        TenderContract.State[] memory,
        address payable[] memory
        )
    {
        bytes32[] memory tenderIds = vendors[msg.sender].tenderIds;
        return getTendersInfo(tenderIds);
    }
    
    function getTendersForBuyer() external view isBuyer returns (
        bytes32[] memory,
        uint[] memory,
        uint256[] memory,
        uint [] memory,
        TenderContract.State[] memory,
        address payable[] memory
        )
    {
        bytes32[] memory tenderIds = buyers[msg.sender].tenderIds;
        return getTendersInfo(tenderIds);
    }
    
    function getTendersInfo(bytes32[] memory tenderIds) private view returns (
        bytes32[] memory,
        uint[] memory,
        uint256[] memory,
        uint [] memory,
        TenderContract.State[] memory,
        address payable[] memory
        )
    {
        bytes32[] memory ids = new bytes32[](tenderIds.length);
        uint[] memory finalPrices = new uint[](tenderIds.length);
        uint256[] memory currentBalances = new uint256[](tenderIds.length);
        uint [] memory expirations = new uint[](tenderIds.length);
        TenderContract.State[] memory states = new TenderContract.State[](tenderIds.length);
        address payable[] memory _vendors = new address payable[](tenderIds.length);
        for (uint i=0; i< tenderIds.length; i++) {
            ids[i] = tenders[tenderIds[i]].id;
            finalPrices[i] = tenders[tenderIds[i]].finalPrice;
            currentBalances[i] = tenders[tenderIds[i]].currentBalance;
            expirations[i] = tenders[tenderIds[i]].expiration;
            states[i] = tenders[tenderIds[i]].state;
            _vendors[i] = tenders[tenderIds[i]].vendor;
        }
        return (ids, finalPrices, currentBalances, expirations, states, _vendors);
    }
    
    event Contribute(bytes32 tenderId);
    function contribute(bytes32 _tenderId) external payable inState(_tenderId, State.Open) {// Contribute = pledge. It should have a timestamp per contributions
        // Check if this is the first time the participants takes part
        Tender storage tender = tenders[_tenderId];
        if (getOrders(_tenderId, msg.sender).length == 0) {
            buyers[msg.sender].tenderIds.push(_tenderId);
        }
        tender.contributors.push(msg.sender);
        tender.contributions[msg.sender].push(Order(msg.value, now));
        tender.currentBalance += msg.value;
        checkIfAmountReached(_tenderId);
        emit Contribute(_tenderId);
    }
}



