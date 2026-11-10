// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IInjectiveExchange {
    struct DerivativeOrder {
        string marketID;
        string subaccountID;
        string feeRecipient;
        uint256 price;
        uint256 quantity;
        string cid;
        string orderType;
        uint256 margin;
        uint256 triggerPrice;
    }

    struct CreateDerivativeLimitOrderResponse {
        string orderHash;
        string cid;
    }

    function createDerivativeLimitOrder(
        address sender,
        DerivativeOrder calldata order
    ) external returns (CreateDerivativeLimitOrderResponse calldata response);

    function deposit(
        address sender,
        string calldata subaccountID,
        string calldata denom,
        uint256 amount
    ) external returns (bool success);
}

contract GuardedVaultProbe {
    IInjectiveExchange private constant exchange =
        IInjectiveExchange(0x0000000000000000000000000000000000000065);

    address public immutable agent;
    bytes32 public immutable allowedMarketHash;
    bytes32 public immutable subaccountHash;
    uint256 public immutable maxNotional;
    uint32 public immutable maxOrdersPerWindow;
    uint64 public immutable windowBlocks;
    string public subaccountID;
    uint64 public windowStartBlock;
    uint32 public ordersInWindow;

    constructor(
        address agent_,
        string memory marketID_,
        string memory subaccountID_,
        uint256 maxNotional_,
        uint32 maxOrdersPerWindow_,
        uint64 windowBlocks_
    ) {
        require(agent_ != address(0), "zero agent");
        require(bytes(marketID_).length != 0, "empty market");
        require(bytes(subaccountID_).length != 0, "empty subaccount");
        require(maxNotional_ != 0, "zero cap");
        require(maxNotional_ <= type(uint256).max / 1e18, "cap overflow");
        require(maxOrdersPerWindow_ != 0, "zero order cap");
        require(windowBlocks_ != 0, "zero window");

        agent = agent_;
        allowedMarketHash = keccak256(bytes(marketID_));
        subaccountHash = keccak256(bytes(subaccountID_));
        maxNotional = maxNotional_;
        maxOrdersPerWindow = maxOrdersPerWindow_;
        windowBlocks = windowBlocks_;
        subaccountID = subaccountID_;
    }

    function deposit(string calldata denom, uint256 amount) external returns (bool) {
        require(msg.sender == agent, "not agent");
        return exchange.deposit(address(this), subaccountID, denom, amount);
    }

    function placeDerivativeLimitOrder(
        IInjectiveExchange.DerivativeOrder calldata order
    ) external returns (IInjectiveExchange.CreateDerivativeLimitOrderResponse memory) {
        require(msg.sender == agent, "not agent");
        require(keccak256(bytes(order.marketID)) == allowedMarketHash, "market denied");
        require(keccak256(bytes(order.subaccountID)) == subaccountHash, "subaccount denied");
        require(order.price != 0 && order.quantity != 0, "empty order");
        require(order.quantity <= (maxNotional * 1e18) / order.price, "notional cap");

        if (block.number >= windowStartBlock + windowBlocks) {
            windowStartBlock = uint64(block.number);
            ordersInWindow = 0;
        }
        require(ordersInWindow < maxOrdersPerWindow, "order rate cap");
        ordersInWindow++;

        return exchange.createDerivativeLimitOrder(address(this), order);
    }
}
