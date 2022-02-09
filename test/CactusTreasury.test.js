const { expect } = require("chai");
const { expectRevert } = require('@openzeppelin/test-helpers');

const fromWei = (n) => web3.utils.fromWei(n.toString());
const bn2String = (bn) => fromWei(bn.toString());
const toWei = (n) => web3.utils.toWei(n.toString());

const CactusTreasury = artifacts.require("CactusTreasury");
const CactusToken = artifacts.require("CactusToken");

require("chai")
  .use(require("chai-as-promised"))
  .should();

contract("CactusTreasury", (accounts) => {

  let token;
  let treasury;

  before(async () => {
    token = await CactusToken.new();
    treasury = await CactusTreasury.new(token.address);
    await token.setTreasuryAddress(treasury.address);
  });

  describe('CactusTreasury', () => {
    it("Check treasutry balance", async function () {
      expect(bn2String(await treasury.balance())).to.equal('0');
    });

    it("Check treasury with funds", async function () {
      await token.transfer(treasury.address, toWei(1000));
      expect(bn2String(await treasury.balance())).to.equal('1000');
    });
  });
});
