const ENC = artifacts.require("ENC");

module.exports = async function(deployer, network, accounts) {

    //goerli
    let WETH = '0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6';
    let pair = '0xfc9f48713f99064634b74b6f9137d05a9d1fe4ec';
    let router = '0xEfF92A263d31888d860bD50809A8D171709b7b1c';
    let receiver = '0x37A5Ec9D194F9d880F28cA28BF6dd75DC81951C3';
    await deployer.deploy(ENC, WETH, pair, router, receiver);

}