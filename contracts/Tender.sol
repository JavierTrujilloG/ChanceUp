pragma solidity 0.6.0;
pragma experimental ABIEncoderV2;

import './Product.sol';
import './SafeMath.sol';

contract TenderContract {
    using SafeMath for uint256;
    
    struct Order {
        uint256 amount;
        uint256 date;
    }
    enum State {
        Cancelled,
        Open,
        Terminate,
        Successful
    }
    
    struct Tender {
        address payable vendor;
        bytes32 id;
        uint finalPrice;
        uint256 currentBalance;
        uint expiration;
        State state;
        mapping (address => Order[]) contributions;
        address payable [] contributors;
        address payable winner;
    }
    
    bytes32[] internal tendersList;
    mapping(bytes32 => Tender) internal tenders;
    
    modifier inState(bytes32 _tender, State _state) {
        require(tenders[_tender].state == _state);
        _;
    }
    
    modifier isTenderVendor(bytes32 _tender) virtual{
        require(msg.sender == tenders[_tender].vendor);
        _;
    }
    
    function getTendersList() public view returns (bytes32[] memory) {
        return tendersList;
    }
    
    function getTenders() public view returns (bytes32[] memory) {
        return tendersList;
    }
    
    /* TODO
    modifier isTenderParticipant(bytes32 _tender) virtual{
        require(msg.sender == tenders[_tender].contributors);
        _;
    }
    */
    
    event CreateTender(bytes32 tenderAddress);
    function createTender (
        address payable creator,
        ProductContract.Product memory product,
        uint durationInDays
    ) internal returns (bytes32) {
        string memory id = createTenderId(product);
        bytes32 idAddress = keccak256(abi.encode(id));
        Tender storage tender = tenders[idAddress];
        address payable vendor = creator;
        uint256 expiration = now.add(uint256(30).mul(1 days)); // By default 30 days for now;
        uint256 finalPrice = product.price;
        uint256 currentBalance = 0;
        tender.vendor = vendor;
        tender.id = idAddress;
        tender.finalPrice = finalPrice;
        tender.currentBalance = currentBalance;
        tender.expiration = expiration;
        tender.state = State.Open;
        tendersList.push(idAddress);
        emit CreateTender(idAddress);
        return idAddress;
    }
    
    function getTenderInformation(bytes32 tenderId) public view returns (
        bytes32,
        uint,
        uint256,
        uint,
        TenderContract.State,
        address payable,
        address payable [] memory
    ) {
        Tender memory tender = tenders[tenderId];

        return (
            tender.id,
            tender.finalPrice,
            tender.currentBalance,
            tender.expiration,
            tender.state,
            tender.vendor,
            tender.contributors
        );
    }
    
    // This should be unique
    function createTenderId(ProductContract.Product memory product) private pure returns (string memory) {
        string memory name = string(abi.encodePacked(product.title, '-'));
        //name = string(abi.encodePacked(product.price, '-'));
        return name;
    }
    
    function checkIfAmountReached(bytes32 _tender) internal {
        Tender storage tender = tenders[_tender];
        if (tender.currentBalance > tender.finalPrice) {
            tender.state = State.Successful;
            completePurchase(msg.sender, _tender);
        }
    }

    function terminate(bytes32 _tender) internal isTenderVendor(_tender){
        Tender storage tender = tenders[_tender];
        tender.state = State.Terminate;
        completePurchase(msg.sender, _tender);
    }
    
    event PurchaseCompleted(address vendor, address winner);
    function completePurchase(address payable vendor, bytes32 _tender) private {
        Tender storage tender = tenders[_tender];
        // TODO oracle
        address payable winner = tender.contributors[(tender.contributors.length - 1)];
        if (vendor.send(tender.currentBalance)) {
            tender.winner = winner;
            emit PurchaseCompleted(vendor, winner);
        }
    }

    function calculateTotalContribution(bytes32 _tender, address contributor) private view returns (uint256) {
        Tender storage tender = tenders[_tender];
        require(tender.contributions[contributor].length > 0);
        uint total = 0;
        Order[] memory orders = tender.contributions[contributor];
        for (uint i = 0; i < orders.length; i++) {
            total += orders[i].amount;
        }
        return total;
    }

    function withdraw(bytes32 _tender, uint amount) external returns (bool){
        require(amount > 0);
        uint totalContributions = calculateTotalContribution(_tender, msg.sender);
        require(totalContributions > amount);
        
        if (!msg.sender.send(amount)) {
            return false;
        } else {
            // TODO bad practice
            Tender storage tender = tenders[_tender];
            tender.contributions[msg.sender].push(Order(-amount, now));
            tender.currentBalance -= amount;
        }
        return true;
    }
    
    function getOrders(bytes32 _tender, address participant) public view returns (Order[] memory) {
        Tender storage tender = tenders[_tender];
        return tender.contributions[participant];
    }
    
    function getParticipantContribution(bytes32 _tender,address participant) public view returns (uint256) {
        return calculateTotalContribution(_tender, participant);
    }
}
