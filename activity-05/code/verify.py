import sys

import pem
from OpenSSL import crypto


def verify(target, intermediate, ca_file="./ca-certificates.crt"):
    with open(target, "r") as cert_file:
        cert = cert_file.read()

    trusted_certs = [str(mypem) for mypem in pem.parse_file(ca_file)]
    # the intermediate file may hold more than one certificate (the whole chain sent by the server)
    if intermediate:
        trusted_certs += [str(mypem) for mypem in pem.parse_file(intermediate)]

    return verify_chain_of_trust(cert, trusted_certs)


def verify_chain_of_trust(cert_pem, trusted_cert_pems):
    certificate = crypto.load_certificate(crypto.FILETYPE_PEM, cert_pem)

    # Create and fill a X509Store with trusted certs
    store = crypto.X509Store()
    for trusted_cert_pem in trusted_cert_pems:
        trusted_cert = crypto.load_certificate(crypto.FILETYPE_PEM, trusted_cert_pem)
        store.add_cert(trusted_cert)

    # Create a X509StoreContext with the cert and trusted certs
    # and verify the chain of trust
    store_ctx = crypto.X509StoreContext(store, certificate)
    try:
        # Returns None if certificate can be validated, raises otherwise
        store_ctx.verify_certificate()
        return True, "OK"
    except crypto.X509StoreContextError as e:
        return False, str(e)


if __name__ == "__main__":
    # Usage: python verify.py <host> [<host> ...]   (run ./get_chain.sh <host> first)
    for host in sys.argv[1:]:
        ok, msg = verify(f"{host}.cert", f"{host}_intermediate.cert")
        print(f"{host:40s} {'Certificate verified' if ok else 'NOT verified: ' + msg}")
