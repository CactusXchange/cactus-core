const CactusToken = artifacts.require("CactusToken");
const CactusTreasury = artifacts.require("CactusTreasury");
const CactusRewarding = artifacts.require("CactusRewarding");

module.exports = async function (deployer) {
  await deployer.deploy(CactusToken);

  await deployer.deploy(CactusTreasury, CactusToken.address);
  await deployer.deploy(CactusRewarding, CactusToken.address);
};