#!/bin/bash

# --- CONFIGURATION ---
LIST="flare_weeks.txt"
FINAL_DIR="./flsf_photons"   
TEMP_DIR="./temp_raw"        
mkdir -p $FINAL_DIR $TEMP_DIR

while read WEEK; do
    echo "--------------------------------------------------"
    echo ">>> TARGETING WEEK: $WEEK"
    
    # 1. Improved Filename Search
    URL_DIR="https://heasarc.gsfc.nasa.gov/FTP/fermi/data/lat/weekly/photon/"
    FILE_NAME=$(curl -s $URL_DIR | grep -o "lat_photon_weekly_w${WEEK}_[^ >]*\.fits" | head -1)

    if [ -z "$FILE_NAME" ]; then
        echo "!!! Error: Could not find Week $WEEK. Server might be busy. Skipping..."
        continue
    fi

    # 2. Download (Removed -q so you can see the speed/progress)
    echo "Downloading $FILE_NAME..."
    
    wget -c -P $TEMP_DIR --progress=dot:giga "${URL_DIR}${FILE_NAME}"
    # 3. gtselect (Filtered for Source Class)
    OUT_FILE="$FINAL_DIR/filtered_photons_w${WEEK}.fits"
    echo "Extracting photons to $OUT_FILE..."
    
    gtselect infile="$TEMP_DIR/$FILE_NAME" \
             outfile="$OUT_FILE" \
             ra=0 dec=0 rad=180 \
             tmin=0 tmax=0 \
             emin=100 emax=300000 \
             zmax=100 \
             evclass=128 evtype=3 \
             chatter=1
    
    # 4. DELETE THE 500MB FILE
    echo "Cleaning up temp file..."
    rm "$TEMP_DIR/$FILE_NAME"
    echo "Done with Week $WEEK."

done < "$LIST"