

import numpy as np
from astropy.io import fits
import os
import warnings

warnings.filterwarnings('ignore')

weeks_file = 'flare_weeks.txt'
photon_dir = './flsf_photons'
exposure_dir = './exposure_data'
output_file = 'solar_cycle_flux.csv'

results = []

with open(weeks_file, 'r') as f:
    weeks = [line.strip() for line in f if line.strip()]

print(f"{'Week':<8} | {'Counts':<10} | {'Exposure':<12} | {'Flux (N/exp)':<12}")
print("-" * 60)

for week in weeks:
    week_pad = week.zfill(3)
    photon_path = os.path.join(photon_dir, f"filtered_photons_w{week}.fits")
    exposure_path = os.path.join(exposure_dir, f"expmap_w{week_pad}.fits")
    
    if not os.path.exists(photon_path) or not os.path.exists(exposure_path):
        continue

    # 1. Get Photon Counts
    with fits.open(photon_path) as hdul:
        counts = len(hdul['EVENTS'].data)
    
    # 2. Get Exposure Value
    with fits.open(exposure_path) as hdul:
        data = hdul[0].data # Shape is (20, 120, 120)
        
        # We take the central portion of the map to avoid edge zeros
        # And we take the mean of the first 5 energy bins (100MeV range)
        # Fermi data stores Energy as the first index in 3D arrays
        core_data = data[0:5, 40:80, 40:80]
        
        # Calculate mean of non-zero values
        if np.any(core_data > 0):
            val = np.mean(core_data[core_data > 0])
        else:
            # Absolute fallback: mean of the entire cube non-zeros
            val = np.mean(data[data > 0]) if np.any(data > 0) else 0
            
    # 3. Calculate Flux
    flux = counts / val if val > 0 else 0
    
    results.append([week, counts, val, flux])
    print(f"{week:<8} | {counts:<10} | {val:<12.2e} | {flux:<12.2e}")

# Save to CSV
header = "week,counts,exposure,flux"
np.savetxt(output_file, results, delimiter=",", header=header, fmt='%s', comments='')
print(f"\nSuccess! Results saved to {output_file}")

