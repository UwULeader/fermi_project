import astropy.io.fits as fits
import matplotlib.pyplot as plt
import numpy as np
import os

target_file = './solar_zooms_fixed/solar_zoom_w381.fits'

if not os.path.exists(target_file):
    print(f"FAILED: {target_file} does not exist yet. Is the bash script still running?")
else:
    print(f"FOUND: {target_file}. Processing...")
    data = fits.getdata(target_file)
    data = np.nan_to_num(data)
    
    # Check if there is any data in the file at all
    total_counts = np.sum(data)
    print(f"Total photon counts in this map: {total_counts}")

    if total_counts == 0:
        print("WARNING: Map is empty. Centering might still be off or no photons were selected.")
    else:
        plt.figure(figsize=(8,8))
        # Square root scaling helps bring out the 'glow' without drowning in noise
        plt.imshow(np.sqrt(data), cmap='magma', origin='lower')
        plt.colorbar(label='Sqrt(Counts)')
        plt.title('September 2014 Flare - Week 381 (Validation)')
        plt.savefig('w381_check.png')
        print("SUCCESS: Image saved as w381_check.png")
