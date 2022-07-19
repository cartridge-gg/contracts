from nile.signer import from_call_to_call_array, get_transaction_hash
from fastecdsa import curve, ecdsa, keys
from hashlib import sha256

BASE = 2 ** 86

class MockP256Signer():
    def __init__(self, private_key=None):
        if private_key is None:
            private_key = keys.gen_private_key(curve.P256)

        pt = keys.get_public_key(private_key, curve.P256)
        x0, x1, x2 = split(pt.x)
        y0, y1, y2 = split(pt.y)

        self.public_key = (x0, x1, x2, y0, y1, y2)
        self.private_key = private_key

    async def send_transaction(self, account, to, selector_name, calldata, nonce=None, max_fee=0):
        return await self.send_transactions(account, [(to, selector_name, calldata)], nonce, max_fee)

    async def send_transactions(self, account, calls, nonce=None, max_fee=0):
        if nonce is None:
            execution_info = await account.get_nonce().call()
            nonce, = execution_info.result

        build_calls = []
        for call in calls:
            build_call = list(call)
            build_call[0] = hex(build_call[0])
            build_calls.append(build_call)

        (call_array, calldata) = from_call_to_call_array(build_calls)
        message_hash = get_transaction_hash(
            account.contract_address, call_array, calldata, nonce, max_fee
        )

        r, s = ecdsa.sign(message_hash.to_bytes(32, byteorder="big"), self.private_key, curve.P256)
        r0, r1, r2 = split(r)
        s0, s1, s2 = split(s)

        print("msg hash", message_hash)
        print("digest", sha256(message_hash.to_bytes(32, byteorder="big")).hexdigest())
        print("part", sha256(int(message_hash & 4294967295).to_bytes(32, byteorder="big") ).hexdigest())

        # the hash and signature are returned for other tests to use
        return await account.__execute__(call_array, calldata, nonce).invoke(
            signature=[0, r0, r1, r2, s0, s1, s2]
        )

def split(G):
    x = divmod(G, BASE)
    y = divmod(x[0], BASE)

    G0 = x[1]
    G1 = y[1]
    G2 = y[0]

    return (G0, G1, G2)


# msg hash 816622422685857688600360285616676331935922084194726557544245148833247104781
# digest de7d3615c9125475e901acf0931a1e50a932efade1cadc58443f37df7947f9d3
     # 0xa67d9e41a632e450130e90484ed4d8a3c3e7234a1b1b3ae301b439800d5c345
# 816622422685857688600360285616676331935922084194726557544245148833247104781
# h0 0xb05ed1aa
# h1 0x68e50478
# h2 0xee8415da
# h3 0x39e8f936
# h4 0xf98dc8d1
# h5 0x9d4557eb
# h6 0x4177fea3
# h7 0xe10b2434

# >>> 0xb05ed1aa * 2 ** 96 + (0x68e50478 * 2 ** 64) + (0xee8415da * 2 ** 32) + 0x39e8f936
# 234436455687705564206581648799360940342

# >>> 0xe10b2434 + 2 ** 32 * 0x4177fea3 + 2 ** 64 * 0x9d4557eb + 2 ** 96 * 0xf98dc8d1
# 331713957896777136473093075791394841652