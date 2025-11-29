#!/usr/bin/env python3
import hashlib
import binascii
import json

# Ed25519 private key (32 bytes)
sk_hex = "526493008e761dea9e9f4cdb46fea7561fc891af37d98ba232b0c7500330ee52"

try:
    from nacl.signing import SigningKey
    sk = SigningKey(binascii.unhexlify(sk_hex))
    vk = sk.verify_key
    vk_hex = binascii.hexlify(bytes(vk)).decode()
except ImportError:
    # Fallback: use ed25519 from cryptography
    from cryptography.hazmat.primitives.asymmetric.ed25519 import Ed25519PrivateKey
    from cryptography.hazmat.primitives import serialization
    
    sk_bytes = binascii.unhexlify(sk_hex)
    private_key = Ed25519PrivateKey.from_private_bytes(sk_bytes)
    public_key = private_key.public_key()
    vk_bytes = public_key.public_bytes(
        encoding=serialization.Encoding.Raw,
        format=serialization.PublicFormat.Raw
    )
    vk_hex = binascii.hexlify(vk_bytes).decode()

print(f"Public Key (hex): {vk_hex}")

# Create verification key file
vk_envelope = {
    "type": "PaymentVerificationKeyShelley_ed25519",
    "description": "Payment Verification Key",
    "cborHex": "5820" + vk_hex
}
print(f"VK Envelope: {json.dumps(vk_envelope, indent=2)}")

# Derive address:
# For Shelley era, enterprise address (no staking) = 0x60 + blake2b-224(vk)
# For testnet: header byte = 0x60 (mainnet) -> 0x61 (testnet network id 0) or 0x60 for preview
# Actually: header = 0110 xxxx where xxxx is network id
# Testnet (preview) = network id 0, so header = 0x60

vk_bytes = binascii.unhexlify(vk_hex)

# Blake2b-224 hash of the verification key
hasher = hashlib.blake2b(vk_bytes, digest_size=28)
key_hash = hasher.digest()
key_hash_hex = binascii.hexlify(key_hash).decode()

print(f"Key Hash (hex): {key_hash_hex}")

# Enterprise address (type 6) for testnet (network id 0)
# Header: 0110 0000 = 0x60
# But for "preview" testnet addresses starting with addr_test1, network id = 0
# Type 6 = enterprise (payment only), network 0 = 0x60

address_bytes = bytes([0x60]) + key_hash
address_hex = binascii.hexlify(address_bytes).decode()

print(f"Address bytes (hex): {address_hex}")

# Bech32 encoding for addr_test1
# We need bech32 library or implement it
def bech32_polymod(values):
    GEN = [0x3b6a57b2, 0x26508e6d, 0x1ea119fa, 0x3d4233dd, 0x2a1462b3]
    chk = 1
    for v in values:
        b = chk >> 25
        chk = ((chk & 0x1ffffff) << 5) ^ v
        for i in range(5):
            chk ^= GEN[i] if ((b >> i) & 1) else 0
    return chk

def bech32_hrp_expand(hrp):
    return [ord(x) >> 5 for x in hrp] + [0] + [ord(x) & 31 for x in hrp]

def bech32_create_checksum(hrp, data):
    values = bech32_hrp_expand(hrp) + data
    polymod = bech32_polymod(values + [0,0,0,0,0,0]) ^ 1
    return [(polymod >> 5 * (5 - i)) & 31 for i in range(6)]

def bech32_encode(hrp, data):
    CHARSET = "qpzry9x8gf2tvdw0s3jn54khce6mua7l"
    combined = data + bech32_create_checksum(hrp, data)
    return hrp + "1" + "".join([CHARSET[d] for d in combined])

def convertbits(data, frombits, tobits, pad=True):
    acc = 0
    bits = 0
    ret = []
    maxv = (1 << tobits) - 1
    for value in data:
        acc = (acc << frombits) | value
        bits += frombits
        while bits >= tobits:
            bits -= tobits
            ret.append((acc >> bits) & maxv)
    if pad:
        if bits:
            ret.append((acc << (tobits - bits)) & maxv)
    elif bits >= frombits or ((acc << (tobits - bits)) & maxv):
        return None
    return ret

# Convert 8-bit to 5-bit
data_5bit = convertbits(list(address_bytes), 8, 5)
address_bech32 = bech32_encode("addr_test", data_5bit)

print(f"\nTestnet Address: {address_bech32}")

# Create initial UTxO JSON
utxo = {
    f"{address_bech32}#0": {
        "address": address_bech32,
        "value": {
            "lovelace": 100000000000  # 100,000 ADA
        }
    },
    f"{address_bech32}#1": {
        "address": address_bech32,
        "value": {
            "lovelace": 50000000000  # 50,000 ADA
        }
    }
}

print(f"\nInitial UTxO JSON:")
print(json.dumps(utxo, indent=2))

# Save files
with open("/tmp/payment.vk", "w") as f:
    json.dump(vk_envelope, f, indent=2)

with open("/tmp/utxo.json", "w") as f:
    json.dump(utxo, f, indent=2)

print("\nFiles saved to /tmp/payment.vk and /tmp/utxo.json")
