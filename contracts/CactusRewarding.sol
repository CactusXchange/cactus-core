//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/ICactusRewarding.sol";
import "./interfaces/ICactusToken.sol";

contract CactusRewarding is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public marketingReserveUsed;

    mapping(address => bool) public operators;
    mapping(address => uint256) public totalReferralCommissions; // referrer address => total referral commissions
    mapping(address => address) public referrers; // user address => referrer address

    event ReferralRecorded(address indexed user, address indexed referrer);
    event OperatorUpdated(address indexed operator, bool indexed status);
    event ReferralCommissionRecorded(
        address indexed referrer,
        uint256 commission
    );
    event ReferralCommissionPaid(
        address indexed user,
        address indexed referrer,
        uint256 commissionAmount
    );

    modifier onlyOperator() {
        require(operators[msg.sender], "Operator: caller is not the operator");
        _;
    }

    ICactusToken public cactt;

    constructor(ICactusToken _cactt) {
        cactt = _cactt;
    }

    function balance() public view returns (uint256) {
        return cactt.balanceOf(address(this));
    }

    function burn(uint256 amount) public onlyOwner {
        cactt.burn(address(this), amount);
    }

    function updateOperator(address _operator, bool _status)
        public
        onlyOwner
    {
        operators[_operator] = _status;
        emit OperatorUpdated(_operator, _status);
    }

    function recordReferralCommission(address _referrer, uint256 _commission)
        public
        onlyOperator
    {
        if (_referrer != address(0) && _commission > 0) {
            totalReferralCommissions[_referrer] += _commission;
            emit ReferralCommissionRecorded(_referrer, _commission);
        }
    }

    // Get the referrer address that referred the user
    function getReferrer(address _user) public view returns (address) {
        return referrers[_user];
    }

    function recordReferral(address _user, address _referrer)
        public
        onlyOperator
    {
        if (
            _user != address(0) &&
            _referrer != address(0) &&
            _user != _referrer &&
            referrers[_user] == address(0)
        ) {
            referrers[_user] = _referrer;
            emit ReferralRecorded(_user, _referrer);
        }
    }

    function payReferrerCommission(address _user, uint256 _value)
        public
        onlyOperator
    {
        address referrer = getReferrer(_user);

        marketingReserveUsed = marketingReserveUsed.add(_value);
        require(
            cactt.MARKETING_RESERVE_AMOUNT() > marketingReserveUsed,
            "Distribution reached its max"
        );

        if (referrer != address(0)) {
            if (cactt.balanceOf(address(this)) > _value) {
                cactt.transfer(referrer, _value);
                recordReferralCommission(referrer, _value);
                emit ReferralCommissionPaid(_user, referrer, _value);
            }
        }
    }
}
