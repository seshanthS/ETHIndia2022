pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

struct UserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    uint256 callGas;
    uint256 verificationGas;
    uint256 preVerificationGas;
    uint256 maxFeePerGas;
    uint256 maxPriorityFeePerGas;
    address paymaster;
    bytes paymasterData;
    bytes signature;
}

interface IentryPoint {
    function getRequestId(UserOperation calldata userOp)
        external
        view
        returns (bytes32);
}

contract BaseAccount {
    using ECDSA for bytes32;

    address public admin;
    mapping(address => bool) public entryPoint;
    uint256 public nonce;

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin");
        _;
    }

    modifier onlyEntryPoint() {
        require(entryPoint[msg.sender], "only entry point");
        _;
    }

    constructor(address _admin, address _entryPoint) {
        admin = _admin;
        entryPoint[_entryPoint] = true;
    }

    function validateUserOp(
        UserOperation calldata userOp,
        bytes32 requestId,
        // address aggregator,
        uint256 missingWalletFunds
    ) external onlyEntryPoint {

        bytes32 userOpHash = IentryPoint(msg.sender).getRequestId(userOp);
        require(requestId == userOpHash, "requestId mismatch");
        address signer = userOpHash.toEthSignedMessageHash().recover(
            userOp.signature
        );
        
        if (userOp.initCode.length == 0) {
            require(userOp.nonce == nonce, "Invalid nonce");
            nonce++;
        }
        _payPrefund(missingWalletFunds);
    }

    function execFromEntryPoint(
        address target,
        uint256 value,
        bytes calldata data
    ) external onlyEntryPoint {
        (bool success, bytes memory result) = target.call{value: value}(data);
        if (!success) {
            assembly {
                revert(add(result, 32), mload(result))
            }
        }
    }

    /**
     * sends to the entrypoint (msg.sender) the missing funds for this transaction.
     * subclass MAY override this method for better funds management
     * (e.g. send to the entryPoint more than the minimum required, so that in future transactions
     * it will not be required to send again)
     * @param missingAccountFunds the minimum value this method should send the entrypoint.
     *  this value MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
     */
    function _payPrefund(uint256 missingAccountFunds) internal virtual {
        if (missingAccountFunds != 0) {
            (bool success, ) = payable(msg.sender).call{
                value: missingAccountFunds,
                gas: type(uint256).max
            }("");
            (success);
            //ignore failure (its EntryPoint's job to verify, not account.)
        }
    }

}
