pragma solidity ^0.4.17;

import "./Algorithm.sol";
import "./BytesUtils.sol";
import "./RSAVerify.sol";
import "./sha1/contracts/sha1.sol";

contract RSASHA1Algorithm is Algorithm {
    using BytesUtils for *;

    function verify(bytes key, bytes data, bytes sig) public view returns (bool) {
        BytesUtils.Slice memory dnskey;
        dnskey.fromBytes(key);

        BytesUtils.Slice memory exponent;
        exponent.copyFrom(dnskey);
        BytesUtils.Slice memory modulus;
        modulus.copyFrom(dnskey);

        BytesUtils.Slice memory sigslice;
        sigslice.fromBytes(sig);

        uint16 exponentLen = uint16(dnskey.uint8At(4));
        if (exponentLen != 0) {
            exponent.s(5, exponentLen + 5);
            modulus.s(exponentLen + 5, dnskey.len);
        } else {
            exponent.s(7, exponentLen + 7);
            modulus.s(exponentLen + 7, dnskey.len);
        }

        // Recover the message from the signature
        if (!RSAVerify.rsarecover(modulus, exponent, sigslice)) {
            return false;
        }
        // Verify it ends with the hash of our data
        bytes20 hash = SHA1.sha1(data);
        bytes20 sigresult = bytes20(sigslice.bytes32At(modulus.len - 32) << 96);
        return hash == sigresult;
    }
}
