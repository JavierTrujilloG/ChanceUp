const ChanceUp = artifacts.require("ChanceUp");

module.exports = async function(callback) {
    try {
        const chanceUp = await ChanceUp.deployed();

        const accounts = await web3.eth.getAccounts();
        const adminAccount = accounts[0];
        const vendorAccount = accounts[1];
        
        // Create vendor
        const vendors = await chanceUp.getVendorList();
        if (vendors.length === 0) {
            // Assign vendor to account
            await chanceUp.addVendor(vendorAccount);
        }

        const buyerAccount = await chanceUp.addBuyer('0xD13f5AC2D7e97B02E0cF11e9cd106103529B9B24');
        

        let productList = await chanceUp.getProductList();
        if (productList.length === 0) {
            // create product
            await chanceUp.createProductForVendor(generateRandomName(), 'Exampless', 20, { from: vendorAccount });
        }
        productList = await chanceUp.getProductList();
        // create Tender
        // TODO create custom getter function
        let tenders = await chanceUp.getTendersList();
        const productId = productList[productList.length - 1];
        await chanceUp.startTender(productId, 3, { from: vendorAccount });

        const tenderAddrs = await chanceUp.getTendersList();
        for (let index = 0; index < tenderAddrs.length; index++) {
            const tenderInfo = await chanceUp.getTenderInformation(tenderAddrs[index]);
            console.log({
                    address: tenderAddrs[index],
                    id: tenderInfo[0],
                    finalPrice: tenderInfo[1].toString(),
                    currentBalance: tenderInfo[2].toString(),
                    expiration: new Date(Number(tenderInfo[3].toString()) * 1000),
                    state: tenderInfo[4].toString(),
                    vendor: tenderInfo[5]
                });
        }

    } catch(e) {
        console.log(e);
    } finally {
        // Finish script
        callback();
    }
};

function generateRandomName() {
    var chars = 'abcdefghijklmnopqrstuvwxyz1234567890';
    var name = 'daisy';
    for(var ii=0; ii<9; ii++){
        name += chars[Math.floor(Math.random() * chars.length)];
    }
    return name;
}
