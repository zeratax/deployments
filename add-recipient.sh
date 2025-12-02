#!/usr/bin/env bash
set -euo pipefail

# Script to add recipients to git-agecrypt.toml
# Usage: ./add-recipient.sh <recipient-key>

if [ $# -ne 1 ]; then
    echo "Usage: $0 <recipient-key>"
    echo "  recipient-key: SSH public key or age public key"
    echo "  Will add recipient to all files matching .gitattributes patterns"
    exit 1
fi

RECIPIENT="$1"
CONFIG_FILE="git-agecrypt.toml"
GITATTRIBUTES_FILE=".gitattributes"

# Validate recipient format
if [[ ! "$RECIPIENT" =~ ^(ssh-|age1) ]]; then
    echo "Error: Recipient must be a valid SSH public key (ssh-*) or age public key (age1*)"
    exit 1
fi

# Parse .gitattributes to find all patterns that use git-agecrypt filter
PATTERNS=()
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue
    
    # Check if line uses git-agecrypt filter
    if [[ "$line" =~ filter=git-agecrypt ]]; then
        # Extract the pattern (everything before the first space)
        pattern=$(echo "$line" | awk '{print $1}')
        PATTERNS+=("$pattern")
    fi
done < "$GITATTRIBUTES_FILE"

if [ ${#PATTERNS[@]} -eq 0 ]; then
    echo "No git-agecrypt patterns found in $GITATTRIBUTES_FILE"
    exit 1
fi

echo "Found ${#PATTERNS[@]} patterns in $GITATTRIBUTES_FILE:"
printf '  %s\n' "${PATTERNS[@]}"

# Find all files matching these patterns
MATCHED_FILES=()
for pattern in "${PATTERNS[@]}"; do
    while IFS= read -r -d '' file; do
        MATCHED_FILES+=("$file")
    done < <(find . -path "./.git" -prune -o -name "$pattern" -print0 2>/dev/null || true)
    
    # Handle directory patterns
    if [[ "$pattern" == *"/**" ]]; then
        dir_pattern="${pattern%/**}"
        if [ -d "$dir_pattern" ]; then
            while IFS= read -r -d '' file; do
                MATCHED_FILES+=("$file")
            done < <(find "$dir_pattern" -type f -print0 2>/dev/null || true)
        fi
    fi
done

# Remove duplicates and sort
IFS=$'\n' MATCHED_FILES=($(printf '%s\n' "${MATCHED_FILES[@]}" | sort -u))

echo "Adding recipient to all matching files in git-agecrypt.toml"

# Create temporary file
TEMP_FILE=$(mktemp)

# Process the config file
awk -v recipient="$RECIPIENT" '
/^\[config\]/ { print; next }
/^".*" = \[$/ { 
    in_array = 1
    print
    next
}
/^\]$/ && in_array {
    # Add the new recipient before closing the array
    print "    \"" recipient "\","
    print
    in_array = 0
    next
}
{ print }
' "$CONFIG_FILE" > "$TEMP_FILE"

# Handle dry run mode
if [ "${DRY_RUN:-}" = "1" ]; then
    echo "=== DRY RUN MODE - Would produce the following git-agecrypt.toml ==="
    cat "$TEMP_FILE"
    rm "$TEMP_FILE"
    echo "=== END DRY RUN ==="
else
    # Replace original file
    mv "$TEMP_FILE" "$CONFIG_FILE"
    echo "Successfully added recipient to all encrypted files: $RECIPIENT"
fi