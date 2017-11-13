#!/bin/bash
INFO()
{
    echo "::" $1
}

KEYLEN=8912
AES=aes256
KEYLEN=1024
AES=aes128

PASSPHRASE="test"

echo -n ${PASSPHRASE} > passphrase.txt
echo -n "hello world!" > message.txt
INFO "generate keys"
INFO "========================================================================"
INFO "> generate private key SENDER with passphrase ${PASSPHRASE}"
openssl genrsa -${AES} -out privateS.pem -passout file:passphrase.txt ${KEYLEN} || exit $?
# generate private key without passphrase: openssl genrsa -out private.pem 8196

INFO "> generate public key SENDER"
openssl rsa -in privateS.pem -passin file:passphrase.txt -pubout -out publicS.pem || exit $?

INFO ""
INFO "> generate private key RECEIVER with passphrase ${PASSPHRASE}"
openssl genrsa -${AES} -out privateR.pem -passout file:passphrase.txt ${KEYLEN} || exit $?
# generate private key without passphrase: openssl genrsa -out private.pem 8196

INFO "> generate public key RECEIVER"
openssl rsa -in privateR.pem -passin file:passphrase.txt -pubout -out publicR.pem || exit $?

INFO ""
INFO "> generate a random key file"
openssl rand 32 -out keyfile || exit $?

INFO "SENDER and RECEIVER have now to exchange their public keys in a safe way"

################################################################################
## Encryption -> on sender side
################################################################################
INFO ""
INFO "SENDER:"
INFO "   Encrypt File with AES Key"
openssl enc -aes-256-cbc -salt -in message.txt -out message.enc -pass file:keyfile || exit $?

INFO "   Encrypt AES Key with Receivers RSA public key"
openssl rsautl -encrypt -inkey publicR.pem -pubin -in keyfile -out keyfile.enc || exit $?

INFO "   Generate a signature for the message.txt with Senders private key"
openssl dgst -sha256 -sign privateS.pem -out signature.txt message.txt  || exit $?

# You can now transmit the file.enc, aesKey.txt.crypted, signature.txt and the public.pem via email or something similar. Dont send the private.p# zem!


################################################################################
## Decryption -> on receiver side
################################################################################
INFO ""
INFO "RECEIVER:"
INFO "   Decrypt AES key with Receivers RSA private key"
openssl rsautl -decrypt -inkey privateR.pem -in keyfile.enc -out keyfile.decrypted -passin file:passphrase.txt || exit $?

INFO "   Decrypt file with AES Key"
openssl enc -d -aes-256-cbc -in message.enc -out message.txt.decrypted -pass file:keyfile.decrypted || exit $?

INFO "   Verify the signature for the recieved file.txt using the senders public key and signature.txt"
openssl dgst -sha256 -verify publicS.pem -signature signature.txt message.txt || exit $?
# in case of success: prints "Verified OK"
# in case of failure: prints "Verification Failure"

exit 0

