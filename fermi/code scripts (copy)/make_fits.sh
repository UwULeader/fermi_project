

# --- CONFIGURATION ---
LIST="flare_weeks.txt"
IN_DIR="./flsf_photons"
OUT_DIR="./flare_maps"
mkdir -p $OUT_DIR

# Standard Unix cleanup
sed -i 's/\r$//' "$LIST"

while read -r WEEK || [ -n "$WEEK" ]; do
    WEEK=$(echo $WEEK | tr -d '[:space:]')
    if [ -z "$WEEK" ]; then continue; fi
    
    WEEK_PAD=$(printf "%03d" $WEEK)
    IN_FILE="$IN_DIR/filtered_photons_w${WEEK_PAD}.fits"
    OUT_FILE="$OUT_DIR/cmap_w${WEEK_PAD}.fits"

    # Try 2-digit name if 3-digit isn't found
    if [ ! -f "$IN_FILE" ]; then
        IN_FILE="$IN_DIR/filtered_photons_w${WEEK}.fits"
    fi

    echo "--------------------------------------------------"
    if [ ! -f "$IN_FILE" ]; then
        echo ">>> Error: $IN_FILE not found."
        continue
    fi

    echo ">>> BINNING COUNT MAP: Week $WEEK_PAD"

    # Reset parameter file
    punlearn gtbin

    # Force-feeding all parameters to prevent interactive prompts
    gtbin evfile="$IN_FILE" \
          scfile="NONE" \
          outfile="$OUT_FILE" \
          algorithm="CMAP" \
          nxpix=360 \
          nypix=180 \
          binsz=1.0 \
          coordsys="CEL" \
          xref=180.0 \
          yref=0.0 \
          axisrot=0.0 \
          proj="AIT" \
          ebinalg="LOG" \
          emin=100.0 \
          emax=300000.0 \
          enumbins=1 \
          chatter=1 < /dev/null

done < "$LIST"

echo "--------------------------------------------------"
echo "DONE! Check $OUT_DIR"
