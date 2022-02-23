//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ICactusToken.sol";

contract CactusWhitelist is Ownable {
    using SafeMath for uint256;

    ICactusToken public cactt;

    mapping(address => HolderInfo) private _whitelistInfo;

    bool public openWhitelist = false;

    address[] private _whitelist;

    uint256 public whitelistSaleDistributed;
    uint256 private _newPaymentInterval = 2592000;
    uint256 private _whitelistHoldingCap = 96000 * 10**18;
    uint256 private _minimumPruchaseInBNB = 2 * 10**18; // 3BNB
    uint256 private _cattPerBNB = 9600; // current price as per the time of private sale

    mapping(address => bool) public operators;

    struct HolderInfo {
        uint256 total;
        uint256 monthlyCredit;
        uint256 amountLocked;
        uint256 nextPaymentUntil;
        uint256 initial;
        bool payedInitial;
    }

    constructor(ICactusToken _cactt) {
        cactt = _cactt;
        operators[owner()] = true;
        emit OperatorUpdated(owner(), true);
    }

    event WhitelistStatusChanged(
        bool indexed previusState,
        bool indexed newState
    );

    function setCACTT(ICactusToken _newCactt) public onlyOwner {
        cactt = _newCactt;
    }

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    event OperatorUpdated(address indexed operator, bool indexed status);

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
            cactt.WHITELIST_ALLOCATION() >= whitelistSaleDistributed,
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
        holder.payedInitial = false;
        holder.initial = initialPayment;
        _whitelistInfo[_account] = holder;
        cactt.burn(owner(), _cattAmount);
    }

    function initialPaymentRelease() public onlyOperator {
        for (uint256 i = 0; i < _whitelist.length; i++) {
            HolderInfo memory holder = _whitelistInfo[_whitelist[i]];
            if (!holder.payedInitial) {
                uint256 amount = holder.initial;
                holder.payedInitial = true;
                holder.initial = 0;
                _whitelistInfo[_whitelist[i]] = holder;
                cactt.mint(_whitelist[i], amount);
            }
        }
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
                cactt.mint(_whitelist[i], holder.monthlyCredit);
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

    function updateOperator(address _operator, bool _status)
        public
        onlyOperator
    {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    function setWhitelistStatus(bool status) public onlyOperator {
        emit WhitelistStatusChanged(openWhitelist, status);
        openWhitelist = status;
    }
}
