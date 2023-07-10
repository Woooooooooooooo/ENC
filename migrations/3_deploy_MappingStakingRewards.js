const MappingStakingRewards = artifacts.require("MappingStakingRewards");

module.exports = async function(deployer, network, accounts) {

    //goerli
    let token = '0x76AcAB7Dc5C6834234305c552FFbfCfCFfa72F0b';
    await deployer.deploy(MappingStakingRewards, token);
    const msr = await MappingStakingRewards.deployed();
    // await msr.notifyRewardAmount(web3.utils.toWei("21600000", "ether"));
    await msr.transferOwnership('0x3026108a822871FB6D08dC45C5e2854b51b79B25');
}