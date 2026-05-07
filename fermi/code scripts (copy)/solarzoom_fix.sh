


# --- CONFIGURATION ---
LIST="flare_weeks.txt"
IN_DIR="./flsf_photons"
OUT_DIR="./solar_zooms_fixed"
TEMP_FT2="./temp_ft2"
mkdir -p $OUT_DIR $TEMP_FT2

# URL for Spacecraft files
URL_DIR="https://heasarc.gsfc.nasa.gov/FTP/fermi/data/lat/weekly/spacecraft/"
curl -s "$URL_DIR" > "$TEMP_FT2/index.html"

# Fix parameter environment
mkdir -p ./pfiles
export PFILES="./pfiles;$(echo $PFILES | cut -d';' -f2-)"

while read -r WEEK || [ -n "$WEEK" ]; do
    WEEK=$(echo $WEEK | tr -d '[:space:]')
    [ -z "$WEEK" ] && continue
    WEEK_PAD=$(printf "%03d" $WEEK)
    
    IN_FILE="$IN_DIR/filtered_photons_w${WEEK_PAD}.fits"
    [ ! -f "$IN_FILE" ] && IN_FILE="$IN_DIR/filtered_photons_w${WEEK}.fits"
    
    if [ ! -f "$IN_FILE" ]; then 
        echo ">>> Skip Week $WEEK: File not found."
        continue
    fi

    echo "--------------------------------------------------"
    echo ">>> PROCESSING FIXED SOLAR ZOOM: Week $WEEK_PAD"

    # 1. Fetch Spacecraft file
    SC_FILE=$(grep -oE "lat_spacecraft_[^ ]*w0*${WEEK}_[^ \">]*\.fits" "$TEMP_FT2/index.html" | head -1)
    if [ -z "$SC_FILE" ]; then
        echo ">>> Error: Could not find SC file for Week $WEEK"
        continue
    fi
    wget -q -c -O "$TEMP_FT2/$SC_FILE" "${URL_DIR}${SC_FILE}"

    # 2. Calculate Sun position (Simplified Python call)
    SUN_POS=$(python -c "import astropy.io.fits as f; from astropy.coordinates import get_sun; from astropy.time import Time; h=f.open('$IN_FILE'); t=h[0].header['TSTART']; h.close(); time=Time((t/86400.0)+51910.0, format='mjd'); sun=get_sun(time); print(f'{sun.ra.deg} {sun.dec.deg}')")
    
    S_RA=$(echo $SUN_POS | awk '{print $1}')
    S_DEC=$(echo $SUN_POS | awk '{print $2}')

    if [ -z "$S_RA" ]; then
        echo ">>> Error: Python failed to calculate Sun position."
        continue
    fi

    echo ">>> Centering on Sun at RA=$S_RA, Dec=$S_DEC"

    # 3. Bin the map
    punlearn gtbin
    gtbin evfile="$IN_FILE" \
          scfile="NONE" \
          outfile="$OUT_DIR/solar_zoom_w${WEEK_PAD}.fits" \
          algorithm="CMAP" \
          nxpix=100 \
          nypix=100 \
          binsz=0.1 \
          coordsys="CEL" \
          xref=$S_RA \
          yref=$S_DEC \
          axisrot=0.0 \
          proj="STG" \
          ebinalg="LOG" \
          emin=100 \
          emax=300000 \
          enumbins=1 \
          chatter=1 < /dev/null

    # Cleanup
    rm -f "$TEMP_FT2/$SC_FILE"

done < "$LIST"

echo "--------------------------------------------------"
echo "DONE! Results are in $OUT_DIR"