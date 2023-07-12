const ENC = artifacts.require("EMBinvite");

module.exports = async function(deployer, network, accounts) {

    //goerli
    let WETH = '0x840f3c7e78b3F642fc5Be7BC9E866D660b0c549F';
    let pair = '0x4229291b1c1EF8664249ddE88F6cF4dB651684cC';
    let router = '0x95e2afe9d2A3Af21762A6C619b70836626B74c19';
    let receiver = '0x37A5Ec9D194F9d880F28cA28BF6dd75DC81951C3';
    await deployer.deploy(ENC, WETH, pair, router, receiver);

}