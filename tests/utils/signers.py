from nile.signer import Signer, from_call_to_call_array, get_transaction_hash
from fastecdsa import curve, ecdsa, keys
from webauthn.helpers import base64url_to_bytes, bytes_to_base64url
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
        return await account.__execute__(call_array, calldata, nonce).invoke(signature=[sig_r, sig_s])

# request
# {
#     "data": {
#         "beginRegistration": {
#             "publicKey": {
#                 "challenge": "pnmCf/BbS0PvHDG5xYNbvv8rNsX4mWOewp66UgXOMwI=",
#                 "rp": {
#                     "name": "Cartridge",
#                     "icon": "https://cartridge.gg/android-chrome-512x512.png",
#                     "id": "cartridge.gg"
#                 },
#                 "user": {
#                     "name": "vitalik",
#                     "icon": "https://cartridge.gg/android-chrome-512x512.png",
#                     "displayName": "vitalik",
#                     "id": "dml0YWxpaw=="
#                 },
#                 "pubKeyCredParams": [
#                     {
#                         "type": "public-key",
#                         "alg": -7
#                     }
#                 ],
#                 "authenticatorSelection": {
#                     "authenticatorAttachment": "platform",
#                     "residentKey": "preferred",
#                     "userVerification": "required"
#                 },
#                 "timeout": 60000,
#                 "attestation": "none"
#             }
#         }
#     }
# }

# response
# {
#     "id": "wPoJLandf4mte3vo2z0IdCvjz4m-IBkNNMMFxM4WMvYZupeb2lmkTMmua2NOt24NUjfpKWuxd0daOMnT7ZgwtJcbmzADfBC-iLhBwkkqqXo0AmmAKvypSqOSSopXPc5IGzQx5JLRn3ijllFvLnp4Ww",
#     "rawId": "wPoJLandf4mte3vo2z0IdCvjz4m-IBkNNMMFxM4WMvYZupeb2lmkTMmua2NOt24NUjfpKWuxd0daOMnT7ZgwtJcbmzADfBC-iLhBwkkqqXo0AmmAKvypSqOSSopXPc5IGzQx5JLRn3ijllFvLnp4Ww",
#     "type": "public-key",
#     "response": {
#         "attestationObject": "o2NmbXRkbm9uZWdhdHRTdG10oGhhdXRoRGF0YVj0IKl-w_jvvCrKDPfKu0ILSgnQrsmQVGbJrfeVhPp1_tNFAAAAAK3OAAI1vMYKZIsLJfHwVQMAcMD6CS2p3X-JrXt76Ns9CHQr48-JviAZDTTDBcTOFjL2GbqXm9pZpEzJrmtjTrduDVI36SlrsXdHWjjJ0-2YMLSXG5swA3wQvoi4QcJJKql6NAJpgCr8qUqjkkqKVz3OSBs0MeSS0Z94o5ZRby56eFulAQIDJiABIVgg-h-cPLElarPVdYG6ZJDmoR5RDdZ9q6DWFeBUChc7RL8iWCCXmqHdyKxX0hn5j1nwjWOowfT1M61HFPA_Fz1fhwmnBw",
#         "clientDataJSON": "eyJ0eXBlIjoid2ViYXV0aG4uY3JlYXRlIiwiY2hhbGxlbmdlIjoicG5tQ2ZfQmJTMFB2SERHNXhZTmJ2djhyTnNYNG1XT2V3cDY2VWdYT013SSIsIm9yaWdpbiI6Imh0dHBzOi8vY29udHJvbGxlci1lMTNwdDl3d3YucHJldmlldy5jYXJ0cmlkZ2UuZ2ciLCJjcm9zc09yaWdpbiI6ZmFsc2UsIm90aGVyX2tleXNfY2FuX2JlX2FkZGVkX2hlcmUiOiJkbyBub3QgY29tcGFyZSBjbGllbnREYXRhSlNPTiBhZ2FpbnN0IGEgdGVtcGxhdGUuIFNlZSBodHRwczovL2dvby5nbC95YWJQZXgifQ"
#     }
# }

# signer:
# privateKey: "0x613d5b38e5713f36c28ea24cc5b29d366d641e24a183b9eb6aeaa2fd2c54534"
# publicKey: "0x01338bbdf1efdda7c04b303c1f3b3a8122a711686c549141508ddd29da7ee2d5"
#            2748922098522874643420764961392724707536570786093336977929361131942676088116

class P256Signer():
    def __init__(self):
        self.signer = StarkSigner(2748922098522874643420764961392724707536570786093336977929361131942676088116)
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

        # challenge = bytes_to_base64url(message_hash.to_bytes(
        #     32, byteorder="big"))
        challenge = message_hash.to_bytes(
            32, byteorder="big").hex()
        print("challenge", challenge)
        client_data_json = f"""{{"type":"webauthn.get","challenge":"0x{challenge}","origin":"https://cartridge.gg","crossOrigin":false}}"""
        client_data_bytes = client_data_json.encode("utf-8")

        client_data_hash = hashlib.sha256()
        client_data_hash.update(client_data_bytes)
        client_data_hash_bytes = client_data_hash.digest()

        client_data_rem = len(client_data_bytes) % 4
        for _ in range(4 - client_data_rem):
            client_data_bytes = client_data_bytes + b'\x00'

        authenticator_data_bytes = bytes.fromhex("20a97ec3f8efbc2aca0cf7cabb420b4a09d0aec9905466c9adf79584fa75fed30500000000")
        authenticator_data_rem = len(authenticator_data_bytes) % 4

        msg_data = authenticator_data_bytes + client_data_hash_bytes
        msg_data_hash = hashlib.sha256()
        msg_data_hash.update(msg_data)
        msg_data_hash_bytes = msg_data_hash.digest()
        print(msg_data_hash_bytes.hex())

        r, s = ecdsa.sign(authenticator_data_bytes + client_data_hash_bytes, self.private_key, curve.P256)
        r0, r1, r2 = split(r)
        s0, s1, s2 = split(s)

        authenticator_data = [int.from_bytes(authenticator_data_bytes[i:i+4], 'big') for i in range(0, len(authenticator_data_bytes), 4)]
        client_data_json = [int.from_bytes(client_data_bytes[i:i+4], 'big') for i in range(0, len(client_data_bytes), 4)]

        print(client_data_bytes)
        print("authenticator_data_len: ", len(authenticator_data), "authenticator_data_rem: ", authenticator_data_rem, "authenticator_data: ", authenticator_data)
        print("client_data_json_len: ", len(client_data_json), "client_data_json_rem: ", client_data_rem, "client_data_json: ", client_data_json)
        
        
        for b in client_data_json:
            print("{0:032b}".format(b))

        # the hash and signature are returned for other tests to use
        return await account.__execute__(call_array, calldata, nonce).invoke(
            signature=[0,
                r0, r1, r2,
                s0, s1, s2,
                9, 2, 8, 1,
                len(client_data_json), client_data_rem, *client_data_json,
                len(authenticator_data), authenticator_data_rem, *authenticator_data,
            ]
        )

def split(G):
    x = divmod(G, BASE)
    y = divmod(x[0], BASE)

    G0 = x[1]
    G1 = y[1]
    G2 = y[0]

    return (G0, G1, G2)


# 0382a1f2b669b853bba3505c8357701bc335fe84aee5d4f2cd681ac7e0eed6c6
# a28c764faedd0a0607ae86ea63508b6a9d604d56b688958308bd1a02301d755b
# b'{"type":"webauthn.get","challenge":"0x0382a1f2b669b853bba3505c8357701bc335fe84aee5d4f2cd681ac7e0eed6c6","origin":"https://cartridge.gg","crossOrigin":false}\x00\x00\x00\x00'
# authenticator_data_len:  10 authenticator_data_rem:  1 authenticator_data:  [547978947, 4176460842, 3389847498, 3141667658, 164671177, 2421450441, 2918684036, 4202036947, 83886080, 0]
# client_data_json_len:  40 client_data_json_rem:  0 client_data_json:  [
# 2065855609, 1885676090, 578250082, 1635087464, 1848534885, 1948396578, 1667785068, 1818586727, 1696741922, 
# 813183027, 942825777, 1714577974, 909730360, 892559970, 1630745904, 895694899, 892811056, 828531507, 859137637, 942956901, 1697997876, 1714578276, 909652321, 1664574768, 1701143606, 1664492076, 577729129, 1734962722, 975333492, 1953526586, 791634785, 1920234089, 1684497710, 1734812204, 576942703, 1936936818, 1768384878, 574252641, 1819501949, 0]
# 
# 58892786 3060381779 3148042332 2203545627 3275095684 2934297842 3446151879 3773748934
# 0x382a1f2 0xb669b853 0xbba3505c 0x8357701b 0xc335fe84 0xaee5d4f2 0xcd681ac7 0xe0eed6c6

# [2065855609, 1885676090, 578250082, 1635087464, 1848534885, 1948396578, 1667785068, 1818586727, 1696741922, 813183029, 879112248, 879125349, 895760226, 825713974, 876044900, 811689528, 1684301368, 926114149, 925983284, 842097465, 859190374, 845559394, 1633891380, 1698183221, 808793654, 1714430508, 577729129, 1734962722, 975333492, 1953526586, 791634785, 1920234089, 1684497710, 1734812204, 576942703, 1936936818, 1768384878, 574252641, 1819501949, 0]
# 89065551 3462232855 3863461130 4175296627 2926687265 3375779631 1806451944 2231723760