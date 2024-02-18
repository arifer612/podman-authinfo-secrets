#!/bin/bash
# @name gpg_store.sh
# @brief podman-authinfo-secrets shell script
# @author Arif Er
# @license GPL-3.0-or-later
# @copyright Copyright © 2024 Arif Er

set -euo pipefail

COMMAND=$1
SECRET_FILE=${2:-""}

SECRETS_STORE="$HOME/.authinfo.gpg"

list() {
    gpg -q --for-your-eyes-only --no-tty -d $SECRETS_STORE |\
        awk "/^machine podman login/{print $4}" ORS=' '
}

lookup() {
    gpg -q --for-your-eyes-only --no-tty -d $SECRETS_STORE |\
        grep $SECRET_ID |\
        awk '{printf $NF}'
}

store() {
    TMPFILE=$(mktemp /tmp/authinfo.XXXXXX)
    gpg --decrypt $SECRETS_STORE > $TMPFILE
    RECIPIENT="$(_get_recipient $TMPFILE)"
    echo "" >> $TMPFILE  # Create a new line
    echo -n "machine podman login ${SECRET_ID} password $(head $SECRET_FILE)" \
         >> $TMPFILE
    sed -i '/^$/d' $TMPFILE  # Delete empty lines
    gpg --encrypt --recipient $RECIPIENT $TMPFILE
    mv $TMPFILE.gpg $SECRETS_STORE
    rm $TMPFILE
}

delete() {
    TMPFILE=$(mktemp /tmp/authinfo.XXXXXX)
    gpg --decrypt $SECRETS_STORE > $TMPFILE
    RECIPIENT="$(_get_recipient $TMPFILE)"
    sed -i "/machine podman login $SECRET_ID/d" $TMPFILE
    gpg --encrypt --recipient $RECIPIENT $TMPFILE
    mv $TMPFILE.gpg $SECRETS_STORE
    rm $TMPFILE
}

_get_recipient() {
    DECRYPTED_FILE=$1
    head -n 1 $DECRYPTED_FILE | cut -d '"' -f 2
}

case $COMMAND in
    list)
        list
        ;;
    lookup)
        lookup
        ;;
    store)
        store
        ;;
    delete)
        delete
        ;;
esac
