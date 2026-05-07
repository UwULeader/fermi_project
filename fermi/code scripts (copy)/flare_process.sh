

# --- CONFIGURATION ---
LIST="flare_weeks.txt"
PHOTON_DIR="./flsf_photons"
CUBE_DIR="./lt_cubes"
TEMP_DIR="./temp_ft2"
mkdir -p $CUBE_DIR $TEMP_DIR

# NASA URL
URL_DIR="https://heasarc.gsfc.nasa.gov/FTP/fermi/data/lat/weekly/spacecraft/"

# Step 1: Get the index once
echo "Fetching NASA index..."
curl -s "$URL_DIR" > "$TEMP_DIR/index.html"

while read WEEK; do
    echo "--------------------------------------------------"
    
    # Check for photon file (handling potential naming variations)
    PH_FILE=$(ls $PHOTON_DIR/filtered_photons_w${WEEK}.fits 2>/dev/null || ls $PHOTON_DIR/filtered_photons_w0${WEEK}.fits 2>/dev/null)
    
    if [ -z "$PH_FILE" ]; then
        echo ">>> Skipping Week $WEEK: No photon file found in $PHOTON_DIR"
        continue
    fi

    # Prepare output name (Standardized to 3 digits for consistency)
    WEEK_PAD=$(printf "%03d" $WEEK)
    OUT_CUBE="$CUBE_DIR/ltcube_w${WEEK_PAD}.fits"

    if [ -f "$OUT_CUBE" ]; then
        echo ">>> Skipping Week $WEEK: Cube already exists."
        continue
    fi

    echo ">>> SEARCHING FOR WEEK $WEEK..."

    # Step 2: Search for the filename using ONLY the week number
    # This matches 'w134' or 'w0134' and ignores 'merged' vs 'weekly'
    SC_FILE=$(grep -oE "lat_spacecraft_[^ ]*w0*${WEEK}_[^ \">]*\.fits" "$TEMP_DIR/index.html" | head -1)

    if [ -z "$SC_FILE" ]; then
        echo "XXX ERROR: Could not find spacecraft file for Week $WEEK."
        continue
    fi

    # Step 3: Download
    echo "Found: $SC_FILE"
    echo "Downloading..."
    wget -q -c -O "$TEMP_DIR/$SC_FILE" "${URL_DIR}${SC_FILE}"

    # Step 4: Run gtltcube
    echo "Calculating Livetime Cube..."
    gtltcube evfile="$PH_FILE" \
             scfile="$TEMP_DIR/$SC_FILE" \
             outfile="$OUT_CUBE" \
             dcostheta=0.025 \
             binsz=1 \
             chatter=1 \
             clobber=yes

    # Step 5: Cleanup
    echo "Cleaning up $SC_FILE..."
    rm -f "$TEMP_DIR/$SC_FILE"

done < "$LIST"

rm -f "$TEMP_DIR/index.html"
echo "PROCESS COMPLETE"