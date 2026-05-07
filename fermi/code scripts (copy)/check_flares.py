

import astropy.io.fits as fits
import matplotlib.pyplot as plt
import numpy as np
import os


def plot_fits(filename, title, output_name):
    if not os.path.exists(filename):
        print(f"File {filename} not found.")
        return

    # Open the FITS file
    with fits.open(filename) as hdul:
        data = hdul[0].data
        # Replace NaNs or negatives with 0 for plotting
        data = np.nan_to_num(data)
        
    plt.figure(figsize=(8, 6))
    # Use a logarithmic scale to see the faint stuff alongside the bright flare
    # Adding 1 to avoid log(0)
    plt.imshow(np.log10(data + 1), cmap='magma', origin='lower')
    plt.colorbar(label='Log10(Counts)')
    plt.title(title)
    plt.xlabel('Pixel X')
    plt.ylabel('Pixel Y')
    plt.savefig(output_name)
    print(f"Saved plot to {output_name}")

# Plot the All-Sky view (Wide)
plot_fits('./flare_maps/cmap_w195.fits', 'All-Sky Gamma Rays (Week 195)', 'all_sky_check.png')

# Plot the Solar Zoom (Close-up)
plot_fits('./solar_zooms/solar_zoom_w195.fits', 'Solar Zoom (Week 195)', 'solar_zoom_check.png')
EOF


