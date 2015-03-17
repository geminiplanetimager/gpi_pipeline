
.. _ifs_data_gallery:

A Gallery of Example Data, Artifacts, and Noise Sources to be Aware Of
===========================================================================


This page is intended as a guide to some of the oddities 
that may occasionally crop up in GPI data. Its goal is to 
help users understand the physical origins of phenomenology seen in
GPI spectral and polarimetric datacubes, and to what extent
the data pipeline can help mitigate any given artifact (or not). 

Anatomy of a GPI Coronagraphic PSF
---------------------------------------

This is what your data *ought* to look like...

**Typical PSF under decent conditions:**

This is a single wavelength slice of H band data. 
You can see the 4 satellite spots, then the 4 more diffuse waffle spots, and then just visible near the upper left and lower right corners you can see two of the second order satellite spots. The waffle spots appear at the 4 corners of the AO dark hole.  These are all entirely normal features (changing in position with wavelength of course).

.. image:: badimg_01_Good_Hband.png
        :scale: 75%
        :align: center


**"Butterfly" from wind**:

The so-called butterfly pattern originates from wind speed defining a preferred direction in the PSF halo. The orientation of the butterfly will depending on which way the wind is blowing across the telescope pupil. 

.. image:: badimg_02_Butterfly.png
        :scale: 75%
        :align: center

**Other Wavelengths:**

Here's one in J band. Now you can also see the diffractive spots from the DM actuator print-through, right at the outer edge of the field. These appear at twice the size of the AO dark hole and waffle spots.   You can also see the butterfly in this one too. 

.. image:: goodimg_Jband.png
        :scale: 75%
        :align: center


Artifacts from AO, Coronagraph, and Telescope Systematics
----------------------------------------------------------


If you see any of the following in your data, there is little the pipeline can do about them. These are all problems that the observer at the telescope should notice and try to fix in real time.


**Misaligned coronagraph:**

If you're operating the instrument, you should use the pointing offsets tool to recenter the star back onto the occulting mask. 

.. image:: badimg_03_MisalignedMask.png
        :scale: 75%
        :align: center

**Bad AOWFS darks:**

This creates an extended pattern in the "vertical" direction on the IFS, due to the orientation of the readout channels of the AOWFS. Fix by opening loops and taking new AOWFS darks. 

.. image:: badimg_04_WFSBias.png
        :scale: 75%
        :align: center

**Misaligned observatory dome:**

The dome controller has crashed and you're clipping the telescope pupil on one side. Time to reboot the dome.   (Or else you started taking data before the dome finished rotating into position on the new target. Slow down!)

.. image:: badimg_05_Dome.png
        :scale: 75%
        :align: center

**37 Hz secondary vibration:**

This problem appeared in January 2015 and intermittently affected observations. Sometimes it made the diffraction spikes start to reappear on either side of the occulter. Note the extended satellite spots, too. 

.. image:: badimg_06_37Hz.png
        :scale: 75%
        :align: center


And sometimes it smeared the data out into an unusable mess: 

.. image:: badimg_10_more_37Hz.png
        :scale: 75%
        :align: center


**Star temporarily moving from behind mask:**

Probably it's very windy. 

.. image:: badimg_07_Peeking.png
        :scale: 75%
        :align: center


Artifacts from IFS and Detector Systematics
-----------------------------------------------

From here on out, the following are things the pipeline can potentially help you deal with. 


**Microphonics noise**


**Persistence**

Examples to be added of spec into pol, pol into spec, flat field into data, etc. 


**Lenslet 30x50 grid**

The lenslet array manufacturing process "prints" lenslets in blocks of 30x50.
This can be seen in spatially filtered flat fields as +-1% variation in the
apparent throughput of pairs of rows/columns every 30th row and 50th column.
Applying a suitable flat field should correct for
this effect in your data (but unless you're trying for <1% photometry on individual lenslets, this is likely to be negligible in practice.) 

.. image:: badimg_08_LensletGrid.png
        :scale: 75%
        :align: center

Artifacts from Data Pipeline Systematics
-----------------------------------------


**Moiré from offset wavecal in datacube assembly**

If you try to create a datacube with a wavecal that is substantially offset
from the spectra (due to e.g. not correcting for flexure) then you can get some entertaining results.  Adjust the wavecal offset to get better cubes. 

.. image:: badimg_09_Moire.png
        :scale: 75%
        :align: center


