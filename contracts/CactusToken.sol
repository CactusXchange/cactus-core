//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/Context.sol";

import "./extensions/BaseToken.sol";

contract CactusToken is
    Context,
    IERC20,
    BaseToken,
    IERC20Metadata,
    Ownable,
    Pausable
{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => HolderInfo) private _whitelistInfo;
    address[] private _whitelist;
    uint256 private _newPaymentInterval = 2592000;
    uint256 private _whitelistHoldingCap = 96000 * 10**decimals();
     uint256 private _minimumPruchaseInBNB = 2 * 10**decimals(); // 3BNB
    uint256 private _cattPerBNB = 9600; // current price as per the time of private sale
    bool public openWhitelist = false;

    mapping(address => bool) public operators;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    bool private _isRegisterAirdropDistribution;

    uint256 private _cap = 120e6 * 10**18; //120,000,000
    uint256 public maxTxFeeBps = 4500;

    address public treasuryContract;
    address public teamAddress;
    address public rewardingContract;
    address public stakingContract;

    uint256 public _liquidityFee;
    uint256 public _marketingFee;

    using SafeMath for uint256;

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    constructor(
        address _teamAddress,
        uint16 liquidityFeeBps_,
        uint16 marketingFeeBps_
    ) {
        require(liquidityFeeBps_ >= 0, "Invalid liquidity fee");
        require(marketingFeeBps_ >= 0, "Invalid marketing fee");
        require(
            liquidityFeeBps_ + marketingFeeBps_ <= maxTxFeeBps,
            "Total fee is over 45%"
        );
        _name = "Cactus";
        _symbol = "CACTT";

        uint256 amount = WHITELIST_ALLOCATION
            .add(PUBLIC_SUPPLY)
            .add(AIRDROP_AMOUNT)
            .add(LIQUIDITY_ALLOCATION);
        _mint(msg.sender, amount);

        _liquidityFee = liquidityFeeBps_;

        teamAddress = _teamAddress;
        _marketingFee = marketingFeeBps_;

        // exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        operators[owner()] = true;
        emit OperatorUpdated(owner(), true);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function excludeFromFee(address account) public onlyOperator {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOperator {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setLiquidityFeePercent(uint256 liquidityFeeBps)
        external
        onlyOperator
    {
        _liquidityFee = liquidityFeeBps;
        require(
            _liquidityFee + _marketingFee <= maxTxFeeBps,
            "Total fee is over 45%"
        );
    }

    function setMarketingFeePercent(uint256 marketingFeeBps)
        external
        onlyOperator
    {
        _marketingFee = marketingFeeBps;
        require(
            _liquidityFee + _marketingFee <= maxTxFeeBps,
            "Total fee is over 45%"
        );
    }

    function initializeReward(address _rewardContract) public onlyOperator {
        rewardingContract = _rewardContract;
        updateOperator(rewardingContract, true);
        marketReserveUsed = marketReserveUsed.add(MARKETING_RESERVE_AMOUNT);
        if (marketReserveUsed <= MARKETING_RESERVE_AMOUNT) {
            _mint(rewardingContract, MARKETING_RESERVE_AMOUNT);
        }
    }

    function mint(address to, uint256 amount) external onlyOperator {
        _mint(to, amount);
    }

    function pause() public onlyOperator {
        _pause();
    }

    function unpause() public onlyOperator {
        _unpause();
    }

    function cap() public view virtual returns (uint256) {
        return _cap;
    }

    function updateOperator(address _operator, bool _status) public onlyOperator {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(totalSupply() + amount <= cap(), "ERC20Capped: cap exceeded");
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function burn(address to, uint256 amount) external onlyOperator {
        _burn(to, amount);
    }

    function getOwner() external view returns (address) {
        return owner();
    }

    function setTreasuryAddress(address _newAddress)
        public
        onlyOperator
        whenNotPaused
    {
        emit TreasuryContractChanged(treasuryContract, _newAddress);
        treasuryContract = _newAddress;
    }

    function distributeAirdrop(address[] memory _receivers, uint256 _value)
        public
        onlyOperator
    {
        require(_isRegisterAirdropDistribution, "not registered ");
        aidropDistributed = aidropDistributed.add(
            _receivers.length.mul(_value)
        );
        require(aidropDistributed <= AIRDROP_AMOUNT, "exceeds max");
        for (uint256 i = 0; i < _receivers.length; i++) {
            _balances[_receivers[i]] = _balances[_receivers[i]].add(_value);
            emit Transfer(address(0), _receivers[i], _value);
        }
    }

    function setTeamAddress(address _newAddress) public onlyOperator {
        require(_newAddress != address(0), "setDevAddress: ZERO");
        emit TeamAddressChanged(treasuryContract, _newAddress);
        teamAddress = _newAddress;
    }

    function setStakingAddress(address _newAddress) public onlyOperator {
        emit StakingAddressChanged(stakingContract, _newAddress);
        stakingContract = _newAddress;
        updateOperator(stakingContract, true);
    }

    function teamMint(uint256 _amount) public onlyOperator {
        teamReserveUsed = teamReserveUsed.add(_amount);
        if (teamReserveUsed <= TEAM_ALLOCATION) {
            _mint(teamAddress, _amount);
        }
    }

    function mintStakingReward(address _recipient, uint256 _amount)
        public
        onlyOperator
    {
        stakingReserveUsed = stakingReserveUsed.add(_amount);
        if (stakingReserveUsed <= STAKING_ALLOCATION) {
            _mint(_recipient, _amount);
        }
    }

    // enable airdroping
    function registerAirdropDistribution() public onlyOperator {
        require(!_isRegisterAirdropDistribution, "Already registered");
        _isRegisterAirdropDistribution = true;
    }

    function registerWhitelist(address _account) external payable {
        require(openWhitelist, "Sale is not in session.");
        require(msg.value > 0, "Invalid amount of BNB sent!");
        uint256 _cattAmount = msg.value * _cattPerBNB;
        whitelistSaleDistributed = whitelistSaleDistributed.add(_cattAmount);
        HolderInfo memory holder = _whitelistInfo[_account];
        if (holder.total <= 0) {
            _whitelist.push(_account);
        }
        require(
            msg.value >= _minimumPruchaseInBNB,
            "Minimum amount to buy is 2BNB"
        );
        require(
            _cattAmount <= _whitelistHoldingCap,
            "You cannot hold more than 10BNB worth of DIBA"
        );
        require(
            WHITELIST_ALLOCATION >= whitelistSaleDistributed,
            "Distribution reached its max"
        );
        require(
            _whitelistHoldingCap >= holder.total.add(_cattAmount),
            "Amount exceeds holding limit!"
        );
        payable(owner()).transfer(msg.value);
        uint256 initialPayment = _cattAmount.div(2); // Release 50% of payment
        uint256 credit = _cattAmount.div(2);

        holder.total = holder.total.add(_cattAmount);
        holder.amountLocked = holder.amountLocked.add(credit);
        holder.monthlyCredit = holder.amountLocked.div(5); // divide amount locked to 5 months
        holder.nextPaymentUntil = block.timestamp.add(_newPaymentInterval);
        _whitelistInfo[_account] = holder;
        _burn(owner(), _cattAmount);
        _mint(_account, initialPayment);
    }

    function timelyWhitelistPaymentRelease() public onlyOperator {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            HolderInfo memory holder = _whitelistInfo[_whitelist[i]];
            if (
                holder.amountLocked > 0 &&
                block.timestamp >= holder.nextPaymentUntil
            ) {
                holder.amountLocked = holder.amountLocked.sub(
                    holder.monthlyCredit
                );
                holder.nextPaymentUntil = block.timestamp.add(
                    _newPaymentInterval
                );
                _whitelistInfo[_whitelist[i]] = holder;
                _mint(_whitelist[i], holder.monthlyCredit);
            }
        }
    }

    function holderInfo(address _holderAddress)
        public
        view
        returns (HolderInfo memory)
    {
        return _whitelistInfo[_holderAddress];
    }

    function setWhitelistStatus(bool status) public onlyOperator {
        emit WhitelistStatusChanged(openWhitelist, status);
        openWhitelist = status;
    }
}
