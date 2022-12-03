pragma solidity 0.8.13;

import "./BaseAccount.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Account is BaseAccount {

    using SafeERC20 for IERC20;

    struct RecuringPaymentData {
        uint256 amount;
        uint256 interval; //in secs
        uint256 lastPayment;//timestamp
        address token;
    }

    mapping(address => RecuringPaymentData) public recuringPayments;

    address public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event ApproveRecurringPayment(address target, uint256 amount, uint256 interval);
    event CancelRecurringPayment(address target);
    event PaymentCollected(address target, uint256 amount);

    error InvalidCollectRequest();

    constructor(address admin, address entryPoint)
        BaseAccount(admin, entryPoint)
    {}

    function approveRecurringPayment(
        address target,
        uint256 amount,
        uint256 interval,
        bool paynow,
        address token
    ) external onlyEntryPoint {
        recuringPayments[target] = RecuringPaymentData({
            amount: amount,
            interval: interval,
            lastPayment: block.timestamp,
            token: token
        });

        if(paynow) {
            _transfer(token, target, amount);
        }

        emit ApproveRecurringPayment(target, amount, interval);
    }

    function cancelRecurringPayment(address target) external onlyEntryPoint {
        delete recuringPayments[target];
        emit CancelRecurringPayment(target);
    }

    function collectPayment(address target) external onlyEntryPoint {
        RecuringPaymentData memory payment = recuringPayments[target];

        if(payment.amount == 0 || payment.lastPayment + payment.interval > block.timestamp) {
            revert InvalidCollectRequest();
        }

        recuringPayments[target].lastPayment = block.timestamp;
        _transfer(payment.token, target, payment.amount);

        emit PaymentCollected(target, payment.amount);
    }

    function _transfer(address token, address target, uint256 amount) internal {
        if(token == ETH) {
            payable(target).transfer(amount);
        } else {
            IERC20(token).safeTransfer(target, amount);
        }
    }

    fallback() external payable {
    }

    receive() external payable {
    }
}
