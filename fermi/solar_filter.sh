

# --- CONFIGURATION ---
LIST="flare_weeks.txt"
PHOTON_DIR="./flsf_photons"
OUT_DIR="./solar_final"
TEMP_DIR="./temp_ft2"
mkdir -p $OUT_DIR $TEMP_DIR

# NASA URL for spacecraft files
URL_DIR="https://heasarc.gsfc.nasa.gov/FTP/fermi/data/lat/weekly/spacecraft/"

# Fetch the index to find filenames
echo "Fetching NASA index for final pass..."
curl -s "$URL_DIR" > "$TEMP_DIR/index.html"

while read WEEK; do
    echo "--------------------------------------------------"
    WEEK_PAD=$(printf "%03d" $WEEK)
    
    # 1. Locate the filtered photon file
    PH_FILE=$(ls $PHOTON_DIR/filtered_photons_w${WEEK}.fits 2>/dev/null || ls $PHOTON_DIR/filtered_photons_w${WEEK_PAD}.fits 2>/dev/null)
    
    if [ -z "$PH_FILE" ]; then
        echo ">>> Skipping Week $WEEK: No photon file found."
        continue
    fi

    # 2. Find and Download the Spacecraft file again
    SC_FILE=$(grep -oE "lat_spacecraft_[^ ]*w0*${WEEK}_[^ \">]*\.fits" "$TEMP_DIR/index.html" | head -1)
    
    if [ -z "$SC_FILE" ]; then
        echo "XXX ERROR: Could not find spacecraft file for Week $WEEK."
        continue
    fi

    echo ">>> FINAL FILTERING FOR WEEK $WEEK_PAD"
    wget -q -c -O "$TEMP_DIR/$SC_FILE" "${URL_DIR}${SC_FILE}"

    # 3. Run gtmktime (The Solar Filter)
    # This filter ensures the Sun is in the field of view and data quality is high
    gtmktime scfile="$TEMP_DIR/$SC_FILE" \
             filter="ANGSEP(RA_SUN,DEC_SUN,RA_ZENITH,DEC_ZENITH)<100 && DATA_QUAL==1 && LAT_CONFIG==1" \
             roicut=no \
             evfile="$PH_FILE" \
             outfile="$OUT_DIR/solar_gamma_w${WEEK_PAD}.fits" \
             chatter=1

    # 4. Cleanup Spacecraft file (keep your disk clean!)
    rm -f "$TEMP_DIR/$SC_FILE"

done < "$LIST"

rm -f "$TEMP_DIR/index.html"
echo "SOLAR FILTER COMPLETE!"