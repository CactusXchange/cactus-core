const CactusToken = artifacts.require("CactusToken");
const CactusTreasury = artifacts.require("CactusTreasury");

module.exports = async function (deployer) {
  await deployer.deploy(CactusToken, '0x72aa50002c9F6216C5f5fDc5a98d89c1D84e00b5', 100, 100);
  await deployer.deploy(CactusTreasury, CactusToken.address);
};