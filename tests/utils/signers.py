from nile.signer import Signer, from_call_to_call_array, get_transaction_hash
from fastecdsa import curve, ecdsa, keys
from webauthn.helpers import bytes_to_base64url
import hashlib

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
        return await account.__execute__(call_array, calldata, nonce).invoke(signature=[self.public_key, sig_r, sig_s])

class ControllerStarkSigner():
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
        return await account.__execute__(call_array, calldata, nonce).invoke(signature=[self.public_key, sig_r, sig_s])

class P256Signer():
    def __init__(self):
        private_key = keys.gen_private_key(curve.P256)
        pt = keys.get_public_key(private_key, curve.P256)
        x0, x1, x2 = split(pt.x)
        y0, y1, y2 = split(pt.y)

        self.public_key = (x0, x1, x2, y0, y1, y2)
        self.private_key = private_key

    async def send_transaction(self, account, to, selector_name, calldata, nonce=None, max_fee=0):
        return await self.send_transactions(account, [(to, selector_name, calldata)], nonce, max_fee)

    def sign_transaction(self, contract_address, call_array, calldata, nonce, max_fee):
        message_hash = get_transaction_hash(
            contract_address, call_array, calldata, nonce, max_fee
        )

        challenge_bytes = message_hash.to_bytes(
            32, byteorder="big")
        # We can add arbitrary bytes after the challenge for the RP challenge
        challenge_bytes = challenge_bytes

        challenge = bytes_to_base64url(challenge_bytes)
        client_data_json = f"""{{"type":"webauthn.get","challenge":"{challenge}","origin":"https://controller.cartridge.gg","crossOrigin":false}}"""
        client_data_bytes = client_data_json.encode("ASCII")

        client_data_hash = hashlib.sha256()
        client_data_hash.update(client_data_bytes)
        client_data_hash_bytes = client_data_hash.digest()

        client_data_rem = 4 - (len(client_data_bytes) % 4)
        if client_data_rem == 4:
            client_data_rem = 0
        if client_data_rem != 0:
            for _ in range(client_data_rem):
                client_data_bytes = client_data_bytes + b'\x00'

        authenticator_data_bytes = bytes.fromhex("20a97ec3f8efbc2aca0cf7cabb420b4a09d0aec9905466c9adf79584fa75fed30500000000")
        authenticator_data_rem = 4 - len(authenticator_data_bytes) % 4
        if authenticator_data_rem == 4:
            authenticator_data_rem = 0

        r, s = ecdsa.sign(authenticator_data_bytes + client_data_hash_bytes, self.private_key, curve.P256)
        r0, r1, r2 = split(r)
        s0, s1, s2 = split(s)

        authenticator_data = [int.from_bytes(authenticator_data_bytes[i:i+4], 'big') for i in range(0, len(authenticator_data_bytes), 4)]
        client_data_json = [int.from_bytes(client_data_bytes[i:i+4], 'big') for i in range(0, len(client_data_bytes), 4)]

        challenge_offset_len = 9
        challenge_offset_rem = 0

        # the hash and signature are returned for other tests to use
        return [
            r0, r1, r2,
            s0, s1, s2,
            challenge_offset_len, challenge_offset_rem,
            len(client_data_json), client_data_rem, *client_data_json,
            len(authenticator_data), authenticator_data_rem, *authenticator_data,
        ]

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

        signature = self.sign_transaction(account.contract_address, call_array, calldata, nonce, max_fee)

        # the hash and signature are returned for other tests to use
        return await account.__execute__(call_array, calldata, nonce).invoke(
            signature=[0, *signature]
        )

def split(G):
    x = divmod(G, BASE)
    y = divmod(x[0], BASE)

    G0 = x[1]
    G1 = y[1]
    G2 = y[0]

    return (G0, G1, G2)
