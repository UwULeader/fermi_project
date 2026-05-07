

LIST="flare_weeks.txt"
TEMP_FT2="./temp_ft2"
INDEX="$TEMP_FT2/index.html"
URL_BASE="https://heasarc.gsfc.nasa.gov/FTP/fermi/data/lat/weekly/spacecraft/"

# Ensure directory exists
mkdir -p $TEMP_FT2

# Refresh the index to be absolutely sure it's current
echo ">>> Refreshing NASA index file..."
wget -q -O "$INDEX" "$URL_BASE"

while read -r WEEK || [ -n "$WEEK" ]; do
    WEEK=$(echo $WEEK | tr -d '[:space:]')
    [ -z "$WEEK" ] && continue
    
    # NEW SEARCH LOGIC: 
    # Look for "lat_spacecraft_" followed by anything, 
    # then "w" followed by your week number, 
    # then ending in .fits
    # This catches both "w082" and "w82"
    REMOTE_FILE=$(grep -oE "lat_spacecraft_[^ \">]*w0*${WEEK}[^ \">]*\.fits" "$INDEX" | head -1)

    if [ -z "$REMOTE_FILE" ]; then
        echo ">>> Week $WEEK: Still not found in index. Checking raw index text..."
        # Last ditch effort: simple grep check
        grep "w${WEEK}" "$INDEX" | head -n 1
        continue
    fi

    echo "--------------------------------------------------"
    echo ">>> Week $WEEK: Found $REMOTE_FILE"
    
    # Download
    wget -c -P "$TEMP_FT2" --show-progress "${URL_BASE}${REMOTE_FILE}"

done < "$LIST"