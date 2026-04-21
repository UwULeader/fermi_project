#!/bin/bash

# Directory setup
PHOTON_DIR="./flsf_photons"
SC_DIR="./temp_ft2"
LTCUBE_DIR="./lt_cubes"
EXPMAP_DIR="./exposure_data"

# Create a temporary python script to handle the dynamic header math
cat << 'EOF' > patch_template.py
import sys
import numpy as np
from astropy.io import fits
import warnings
warnings.filterwarnings('ignore')

photon_file = sys.argv[1]
template_file = sys.argv[2]

# 1. Read Sun's average coordinate for the week
with fits.open(photon_file) as hdul:
    ra_mean = np.mean(hdul['EVENTS'].data['RA'])
    dec_mean = np.mean(hdul['EVENTS'].data['DEC'])

# 2. Patch the template to fix the metadata cuts
with fits.open(template_file, mode='update') as hdul:
    hdr = hdul['EVENTS'].header
    # Wipe the confusing keys
    for i in range(1, 10):
        for key in ['DSTYP', 'DSUNI', 'DSVAL', 'DSREF']:
            k = f'{key}{i}'
            if k in hdr: del hdr[k]

    # Inject the strict 'Big Three' keys
    hdr['NDSKEYS'] = 3
    hdr['DSTYP1'], hdr['DSUNI1'], hdr['DSVAL1'], hdr['DSREF1'] = 'TIME', 's', 'TABLE', ':GTI'
    hdr['DSTYP2'], hdr['DSUNI2'], hdr['DSVAL2'] = 'ENERGY', 'MeV', '100:300000'
    hdr['DSTYP3'], hdr['DSUNI3'], hdr['DSVAL3'] = 'POS(RA,DEC)', 'deg', f'CIRCLE({ra_mean:.2f},{dec_mean:.2f},20)'
    hdul.flush()
EOF

# Loop through all available weeks in flsf_photons
for file in ${PHOTON_DIR}/filtered_photons_w*.fits; do
    
    # Extract the week number and format it
    # This handles both "w82" and "w082" naming mismatches
    filename=$(basename "$file")
    week_str=${filename#filtered_photons_w}
    week_str=${week_str%.fits}
    padded_week=$(printf "%03d" $week_str)

    echo "=================================================="
    echo "Processing Week $padded_week..."
    echo "=================================================="

    SC_FILE="${SC_DIR}/lat_spacecraft_weekly_w${padded_week}_p310_v001.fits"
    
    # Failsafe: Check if Spacecraft file exists
    if [ ! -f "$SC_FILE" ]; then
        echo "ERROR: Spacecraft file $SC_FILE not found! Skipping..."
        continue
    fi

    # Setup file names for this loop
    TEMPLATE="temp_template_w${padded_week}.fits"
    LTCUBE="${LTCUBE_DIR}/ltcube_w${padded_week}_fixed.fits"
    EXPMAP="${EXPMAP_DIR}/expmap_w${padded_week}.fits"

    # Step 1: Create a fresh copy of the photon file to act as the template
    cp "$file" "$TEMPLATE"

    # Step 2: Run our Python patcher to center it on the Sun
    python patch_template.py "$file" "$TEMPLATE"

    # Step 3: Regenerate the Livetime Cube (The Fix!)
    echo ">>> Generating Livetime Cube..."
    gtltcube evfile="$file" \
             scfile="$SC_FILE" \
             outfile="$LTCUBE" \
             dcostheta=0.025 \
             binsz=1 \
             zmax=100 \
             clobber=yes chatter=0

    # Step 4: Generate the Exposure Map
    echo ">>> Generating Exposure Map..."
    gtexpmap evfile="$TEMPLATE" \
             scfile="$SC_FILE" \
             expcube="$LTCUBE" \
             outfile="$EXPMAP" \
             irfs="P8R3_SOURCE_V3" \
             srcrad=20 nlong=120 nlat=120 nenergies=20 \
             clobber=yes chatter=0

    # Cleanup temporary template
    rm "$TEMPLATE"
    echo ">>> Finished Week $padded_week."
done

# Final cleanup
rm patch_template.py
echo "ALL WEEKS COMPLETED SUCCESSFULLY!"


#just ran it in bash, putting it here 
