
req <- readRDS("./inst/request.RDS")
ls(req)

req$HTTP_SIGNATURE
req$HTTP_SIGNATURECERTCHAINURL


# Download cert
req$HTTP_SIGNATURECERTCHAINURL

library(openssl)

# TODO: cache cert URL handling

# 1. Verify that the URL matches the format used by amazon
# TODO

# 2. Download the PEM Cert file
download.file(req$HTTP_SIGNATURECERTCHAINURL, "amazon.crt")
chain <- openssl::read_cert_bundle("amazon.crt")

# 3.
#   3a. Check the `Not Before` and `Not After` dates
# TODO
# chain[[1]]$validity

#   3b. Check that it's an echo domain cert
forEcho <- grepl("echo-api.amazon.com", chain[[1]]$subject, fixed = TRUE)
if (!forEcho){
  stop("Invalid cert domain")
}

#   3c. Chain points to a trusted root CA
valid <- openssl::cert_verify(chain)
if (!valid){
  stop("Invalid cert!")
}

# 4. Get the public key from the cert
pubkey <- openssl::read_pubkey(chain[[1]])

# 5. Base64-decode the Signature header value
encSig <- openssl::base64_decode(req$HTTP_SIGNATURE)

# 6. Decrypt the encrypted hash value
# 7. Generate the SHA1 hash of the request body
# 8. Compare the hashes
body <- req$postBody
signature_verify(data=charToRaw(body), sig=encSig, hash=openssl::sha1, pubkey=pubkey)

# 9. Check timestamp
#TODO
