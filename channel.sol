pragma solidity ^0.4.0;

contract Channel {

	address public channelSender;
	address public channelRecipient;
	uint public startDate;
	uint public channelTimeout;
	mapping (bytes32 => address) signatures;

	function Channel(address to, uint timeout) payable {
		channelRecipient = to;
		channelSender = msg.sender;
		startDate = now;
		channelTimeout = timeout;
	}

	function CloseChannel(bytes32 h, uint8 v, bytes32 r, bytes32 s, uint value, bytes32 hashedkey, bytes32 key){

		address signer;
		bytes32 proof;

		// get signer from signature
		signer = ecrecover(h, v, r, s);

		// signature is invalid, throw
		if (signer != channelSender && signer != channelRecipient) throw;

		proof = sha3(this, value, hashedkey);

		// if the signer is the recipient, they should provide the key
		if (signer == channelRecipient && sha3(key) != hashedkey) throw;

		// signature is valid but doesn't match the data provided
		if (proof != h) throw;

		if (signatures[proof] == 0)
			signatures[proof] = signer;
		else if (signatures[proof] != signer){
			// channel completed, both signatures provided
			if (!channelRecipient.send(value)) throw;
			selfdestruct(channelSender);
		}

	}

	function ChannelTimeout(){
		if (startDate + channelTimeout > now)
			throw;

		selfdestruct(channelSender);
	}

}
