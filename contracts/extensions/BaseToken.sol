//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract BaseToken {
    uint256 public constant AIRDROP_AMOUNT = 120e4 * 10**18; //1,200,000
    uint256 public constant WHITELIST_ALLOCATION = 48e5 * 10**18; //4,800,000
    uint256 public constant PUBLIC_SUPPLY = 6e6 * 10**18; //6,000,000
    uint256 public constant LIQUIDITY_ALLOCATION = 6e6 * 10**18; //6,000,000
    uint256 public constant TEAM_ALLOCATION = 12e6 * 10**18; //12,000,000
    uint256 public constant MARKETING_RESERVE_AMOUNT = 6e6 * 10**18; //6,000,000
    uint256 public constant STAKING_ALLOCATION = 84e6 * 10**18; //84,000,000

    uint256 public aidropDistributed;
    uint256 public whitelistSaleDistributed;
    uint256 public publicSaleDistributed;
    uint256 public stakingReserveUsed;
    uint256 public liquidityReserveUsed;
    uint256 public teamReserveUsed;
    uint256 public marketReserveUsed;

    struct HolderInfo {
        uint256 total;
        uint256 monthlyCredit;
        uint256 amountLocked;
        uint256 nextPaymentUntil;
    }

    event TreasuryContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event OperatorUpdated(address indexed operator, bool indexed status);

    event TeamAddressChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event StakingAddressChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event RewardingContractChanged(
        address indexed previusAAddress,
        address indexed newAddress
    );

    event WhitelistStatusChanged(
        bool indexed previusState,
        bool indexed newState
    );
}
