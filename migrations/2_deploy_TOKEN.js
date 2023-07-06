const Token = artifacts.require("Token");

module.exports = async function(deployer, network, accounts) {

    TextDecoderStreamded;    
    await deployer.deploy(Token, "USDT", "USDT", '0x7bb856c9E6b192bA486C57BD5Dd5F54Ddd370243');

}