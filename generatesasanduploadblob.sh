#!/bin/bash

echo "usage: ${0##*/} <RESOURCE_GROUP_NAME> <STORAGE_ACCOUNT_NAME> <CONTAINER_NAME> <BLOB_FULL_PATH>"

urlencode() {
    # urlencode <string>
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

RESOURCE_GROUP_NAME=$1
STORAGE_ACCOUNT_NAME=$2
CONTAINER_NAME=$3
BLOB_FULL_PATH=$4
BLOB_NAME=$(basename $BLOB_FULL_PATH)
PRIMARY_KEY=$(az storage account keys list -g $RESOURCE_GROUP_NAME -n $STORAGE_ACCOUNT_NAME --query "[0].value" -o tsv)
VERSION="2019-07-07"
DECODED_KEY="$(echo -n $PRIMARY_KEY | base64 -d -w0 | xxd -p -c256)"
DATE_ISO=$(TZ=GMT date "+%a, %d %h %Y %H:%M:%S %Z")
DATE_ISO8601=$(TZ=GMT date --date="${DATE_ISO}" "+%Y-%m-%dT%H:%M:%SZ")
DATEPLUSONE_ISO8601=$(TZ=GMT date -d "+1 days" "+%Y-%m-%dT%H:%M:%SZ")
CANONICALIZEDRESOURCE="/blob/${STORAGE_ACCOUNT_NAME}/${CONTAINER_NAME}"
SIGNED_RESOURCE="c"

# Container permissions can be granular (ordering is important)
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#permissions-for-a-container
SAS_PERMS="rcw"

# /*Signed permissions*/
STRING_TO_SIGN="${SAS_PERMS}\n"
# /*Signed start*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-the-signature-validity-interval
STRING_TO_SIGN="${STRING_TO_SIGN}${DATE_ISO8601}\n"  
# /*Signed expiry*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-the-signature-validity-interval
STRING_TO_SIGN="${STRING_TO_SIGN}${DATEPLUSONE_ISO8601}\n"
# /*Canonicalized resource*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#versions-prior-to-2012-02-12
STRING_TO_SIGN="${STRING_TO_SIGN}${CANONICALIZEDRESOURCE}\n"
# /*Signed identifier*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"  
# /*Signed IP address or address range*/ 
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-ip-address-or-ip-range
STRING_TO_SIGN="${STRING_TO_SIGN}\n"  
# /*Signed protocol*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-the-http-protocol
STRING_TO_SIGN="${STRING_TO_SIGN}https\n"  
# /*Signed version*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-the-signed-version-field
STRING_TO_SIGN="${STRING_TO_SIGN}${VERSION}\n" 
# /*Signed resource*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-the-signed-resource-blob-service-only
STRING_TO_SIGN="${STRING_TO_SIGN}${SIGNED_RESOURCE}\n"
# /*Signed snaptshot time*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Cache-Control return header*/
# https://docs.microsoft.com/rest/api/storageservices/create-service-sas#specifying-query-parameters-to-override-response-headers-blob-and-file-services-only
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Content-Disposition return header*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Content-Encoding return header*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Content-Language return header*/
STRING_TO_SIGN="${STRING_TO_SIGN}\n"
# /*Content-Type return header*/
STRING_TO_SIGN="${STRING_TO_SIGN}"

SIGNATURE_SAS=$(printf "${STRING_TO_SIGN}" | openssl dgst -sha256 -mac HMAC -macopt "hexkey:$DECODED_KEY" -binary | base64 -w0)

echo "SAS signature: ${SIGNATURE_SAS}"

SAS_TOKEN="sv=${VERSION}"

DATE_ISO8601_ENC=$(urlencode $DATE_ISO8601)
DATEPLUSONE_ISO8601_ENC=$(urlencode $DATEPLUSONE_ISO8601)
SIGNATURE_SAS_ENC=$(urlencode $SIGNATURE_SAS)

SAS_TOKEN="${SAS_TOKEN}&st=${DATE_ISO8601_ENC}"
SAS_TOKEN="${SAS_TOKEN}&se=${DATEPLUSONE_ISO8601_ENC}"
SAS_TOKEN="${SAS_TOKEN}&sr=${SIGNED_RESOURCE}"
SAS_TOKEN="${SAS_TOKEN}&sp=${SAS_PERMS}"
SAS_TOKEN="${SAS_TOKEN}&spr=https"
SAS_TOKEN="${SAS_TOKEN}&sig=${SIGNATURE_SAS_ENC}"

echo "SAS token: ${SAS_TOKEN}"

curl -X PUT \
    -T $BLOB_FULL_PATH \
    -H "x-ms-date:${DATE_ISO}" \
    -H "x-ms-version:${VERSION}" \
    -H "x-ms-blob-type: BlockBlob" \
    -H "Content-Type: text/plain; charset=UTF-8" \
    "https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net/${CONTAINER_NAME}/${BLOB_NAME}?${SAS_TOKEN}"