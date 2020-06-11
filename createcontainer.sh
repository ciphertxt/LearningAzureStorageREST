#!/bin/bash

echo "usage: ${0##*/} <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME> <CONTAINER_NAME>"

RESOURCE_GROUP_NAME=$1
STORAGE_ACCOUNT_NAME=$2
CONTAINER_NAME=$3
PRIMARY_KEY=$(az storage account keys list -g $RESOURCE_GROUP_NAME -n $STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)
VERSION="2019-07-07"
DECODED_KEY="$(echo -n $PRIMARY_KEY | base64 -d -w0 | xxd -p -c256)"
DATE_ISO=$(TZ=GMT date "+%a, %d %h %Y %H:%M:%S %Z")

# /*HTTP Verb*/  
STRING_TO_SIGN="PUT\n"
# /*Content-Encoding*/ 
STRING_TO_SIGN="${STRING_TO_SIGN}\n"     
# /*Content-Language*/ 
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Content-Length (empty string when zero)*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Content-MD5*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"  
# /*Content-Type*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"  
# /*Date*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n" 
# /*If-Modified-Since */
STRING_TO_SIGN="${STRING_TO_SIGN}\n"  
# /*If-Match*/ 
STRING_TO_SIGN="${STRING_TO_SIGN}\n"     
# /*If-None-Match*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*If-Unmodified-Since*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"  
# /*Range*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*CanonicalizedHeaders*/
STRING_TO_SIGN="${STRING_TO_SIGN}x-ms-date:${DATE_ISO}\nx-ms-version:${VERSION}\n"
# /*CanonicalizedResource*/
STRING_TO_SIGN="${STRING_TO_SIGN}/${STORAGE_ACCOUNT_NAME}/${CONTAINER_NAME}\nrestype:container"

SIGNATURE=$(printf "${STRING_TO_SIGN}" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$DECODED_KEY" -binary | base64 -w0)

curl -X PUT \
    -H "x-ms-date:${DATE_ISO}" \
    -H "x-ms-version:${VERSION}" \
    -H "Authorization: SharedKey ${STORAGE_ACCOUNT_NAME}:${SIGNATURE}" \
    -H "Content-Length: 0" \
    "https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}?restype=container"