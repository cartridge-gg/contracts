from nile.signer import Signer, from_call_to_call_array, get_transaction_hash
from fastecdsa import curve, ecdsa, keys

BASE = 2 ** 86

class StarkSigner():
    def __init__(self, private_key):
        self.signer = Signer(private_key)
        self.public_key = self.signer.public_key

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

        (call_array, calldata, sig_r, sig_s) = self.signer.sign_transaction(hex(account.contract_address), build_calls, nonce, max_fee)
        return await account.__execute__(call_array, calldata, nonce).invoke(signature=[sig_r, sig_s])


class P256Signer():
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

        r, s = ecdsa.sign(message_hash.to_bytes(
            32, byteorder="big"), self.private_key, curve.P256)
        r0, r1, r2 = split(r)
        s0, s1, s2 = split(s)

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
