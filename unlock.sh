#!/usr/bin/env bash
set -euo pipefail

# Unlock strongbox-encrypted files in this repository.
#
# Prerequisites:
#   1. strongbox must be installed and configured:
#        strongbox -git-config
#   2. Your age identity must be saved to ~/.strongbox_identity
#      (get it from another team member or your backup)
#
# Usage: ./unlock.sh

IDENTITY_FILE="$HOME/.strongbox_identity"

if [ ! -f "$IDENTITY_FILE" ]; then
    echo "Error: $IDENTITY_FILE not found."
    echo ""
    echo "To set up access:"
    echo "  1. Generate a new keypair:  age-keygen -o $IDENTITY_FILE"
    echo "  2. Add your public key to .strongbox_recipient in this repo"
    echo "  3. Have someone with access re-encrypt the files"
    echo ""
    echo "Or restore your existing identity from backup."
    exit 1
fi

GITATTRIBUTES=".gitattributes"
ENCRYPTED_FILES=()

while IFS= read -r line; do
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    if [[ "$line" =~ filter=strongbox ]]; then
        pattern=$(echo "$line" | awk '{print $1}')
        while IFS= read -r -d '' file; do
            ENCRYPTED_FILES+=("$file")
        done < <(git ls-files -z -- "$pattern" 2>/dev/null)
    fi
done < "$GITATTRIBUTES"

if [ ${#ENCRYPTED_FILES[@]} -eq 0 ]; then
    echo "No encrypted files found."
    exit 0
fi

echo "Decrypting ${#ENCRYPTED_FILES[@]} files..."

rm -f "${ENCRYPTED_FILES[@]}"
git checkout -- "${ENCRYPTED_FILES[@]}"

echo "Done. All encrypted files have been decrypted."
