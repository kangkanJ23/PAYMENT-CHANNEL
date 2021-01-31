pragma solidity ^0.6.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/cryptography/ECDSA.sol";

contract UniDirectionalPayment {
    using ECDSA for bytes32;

    address payable public sender;
    address public receiver;
    uint public withdrawn;

    uint public closeDuration;

    uint public expiresAt = 2**256-1;

    constructor(address _receiver, uint _closeDuration) public {
        require(_receiver!=address(0));
        require(_closeDuration > 3 days);

        sender = msg.sender;
        receiver = _receiver;
        closeDuration = _closeDuration;
    }

    function isValidSignature(uint amount, bytes memory signature) internal view returns(bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), amount));
        bytes32 message = ECDSA.toEthSignedMessageHash(hash);
        return ECDSA.recover(message, signature) == sender;
    }

    function close(uint totalAmount, bytes memory signature) public {
        require(msg.sender == receiver);
        require(isValidSignature(totalAmount, signature));
        require(totalAmount >= withdrawn);

        msg.sender.transfer(totalAmount - withdrawn);
        selfdestruct(sender);
    }

    function closeInitiatedBySender() public {
        require(msg.sender == sender);
        expiresAt = now + closeDuration;
    }

    function claimAmountPostTimeOut() public {
        require(msg.sender == sender);
        require(now >= expiresAt);
        selfdestruct(sender);
    }

    function deposit() public payable {
        require(msg.sender == sender);
    }

    function withdraw(uint amountAuthorized, bytes memory signature) public {
        require(msg.sender == receiver);
        require(isValidSignature(amountAuthorized, signature));
        require(amountAuthorized > withdrawn);

        uint amountToWithdraw = amountAuthorized - withdrawn;
        withdrawn+=amountToWithdraw;
        msg.sender.transfer(amountToWithdraw);
    }
}
