from fastecdsa import curve, ecdsa, keys

class P256Signer():
    def __init__(self, private_key=None):
        if private_key is None:
            private_key = keys.gen_private_key(curve.P256)

        self.public_key = keys.get_public_key(private_key, curve.P256)
        self.private_key = private_key

    def sign(self, message_hash):
        return ecdsa.sign(message_hash, self.private_key, curve.P256)
