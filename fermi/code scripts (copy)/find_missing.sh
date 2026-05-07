


MASTER_LIST="flare_weeks.txt"
MISSING_LIST="missing_weeks.txt"
TEMP_FT2="./temp_ft2"

# Clear out the old list
> "$MISSING_LIST"

echo ">>> Scanning $TEMP_FT2 for missing spacecraft files..."

while read -r WEEK || [ -n "$WEEK" ]; do
    WEEK=$(echo $WEEK | tr -d '[:space:]')
    [ -z "$WEEK" ] && continue
    
    # Force the week to be exactly 3 digits (e.g., 82 becomes 082, 107 stays 107)
    PADDED_WEEK=$(printf "%03d" ${WEEK#0}) # Removes leading zeros first to prevent octal math errors

    # Check for the correct file
    if ! ls ${TEMP_FT2}/lat_spacecraft_*w${PADDED_WEEK}*.fits 1> /dev/null 2>&1; then
        echo "Missing: Week $WEEK"
        echo "$WEEK" >> "$MISSING_LIST"
    fi
done < "$MASTER_LIST"

MISSING_COUNT=$(wc -l < "$MISSING_LIST")
echo ">>> Scan complete! Found $MISSING_COUNT missing weeks."