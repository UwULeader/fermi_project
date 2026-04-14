


# --- CONFIGURATION ---
LIST="flare_weeks.txt"
IN_DIR="./flsf_photons"
OUT_DIR="./solar_zooms"
mkdir -p $OUT_DIR

# Clean the list
sed -i 's/\r$//' "$LIST"

# --- FIX PARAMETER ERRORS ---
# This creates a fresh, local directory for Fermi parameter files 
# to prevent "Exception while querying" errors.
mkdir -p ./pfiles
export PFILES="./pfiles;$(echo $PFILES | cut -d';' -f2-)"

while read -r WEEK || [ -n "$WEEK" ]; do
    WEEK=$(echo $WEEK | tr -d '[:space:]')
    [ -z "$WEEK" ] && continue
    WEEK_PAD=$(printf "%03d" $WEEK)
    
    # Try both padded and unpadded filenames
    IN_FILE="$IN_DIR/filtered_photons_w${WEEK_PAD}.fits"
    if [ ! -f "$IN_FILE" ]; then
        IN_FILE="$IN_DIR/filtered_photons_w${WEEK}.fits"
    fi

    OUT_FILE="$OUT_DIR/solar_zoom_w${WEEK_PAD}.fits"

    echo "--------------------------------------------------"
    if [ ! -f "$IN_FILE" ]; then
        echo ">>> Error: $IN_FILE not found. Skipping..."
        continue
    fi

    echo ">>> BINNING ZOOM MAP: Week $WEEK_PAD"

    # Reset gtbin parameters in our fresh pfiles directory
    punlearn gtbin

    # Force-feeding EVERY parameter to stop the tool from asking questions
    gtbin evfile="$IN_FILE" \
          scfile="NONE" \
          outfile="$OUT_FILE" \
          algorithm="CMAP" \
          nxpix=200 \
          nypix=200 \
          binsz=0.1 \
          coordsys="CEL" \
          xref=351.2 \
          yref=-3.2 \
          axisrot=0.0 \
          proj="STG" \
          ebinalg="LOG" \
          emin=100 \
          emax=300000 \
          enumbins=1 \
          chatter=1 < /dev/null

done < "$LIST"

echo "--------------------------------------------------"
echo "DONE! Files are in $OUT_DIR"