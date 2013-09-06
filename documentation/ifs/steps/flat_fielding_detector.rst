
Flat Fielding
==============================

.. warning::
   This is one of the areas where algorithms are still in flux and calibration methods are not fully mature.


Observed Effect and Relevant Physics:
---------------------------------------

The goal of a flat-field is to correct for transmission of the instrument as a function of field-of-view. This includes multiple contibuting effects including:

   #. Quantum efficiency variations of the Detector (includes: intrapixel sensitivity variations, pixel-to-pixel variations and low-frequency variations).
   #. Field dependent instrument transmission (includes such effects vignetting (not present in GPI), optical element transmission variations etc.)

Whereas traditional imagers/spectrographs illuminate the entire detector (or portion of interest) in order to determine the majority of the above effects simultaneously, the permanently installed lenslet array in GPI, prohibits a uniform illumination. 

Until recently, the flat-fielding has been performed by flood illuminating the instrument using an integration sphere inserted into the telescope simulator. The data was then reduced into a data-cube and the median lamp spectrum removed. Assuming the illumination to be uniform, this provides a calibration of the instrument sensitivity as a function of field of view (including the transmission properties of the lenslet array), and a calibration for the excluded flux when using the 3-pixel box extraction algorithm (see :doc:`datacube_extraction` for details). This algorithm also accounts for the pixel-to-pixel variations, so long as the spectra in the science image rests exactly at the same position as the spectra from the flat lamp. For this scenario, the flat-fielding is done in datacube space, rather than detector space (the tradiation method).

The fundamental problem with this scenario is its failure to account for the effect of flexure. As the instrument flexs, the spectra are moved onto different pixels that are not illuminated by the flat field. This causes multiple problems.

   #. As there is no illumination of the adjacent pixels in the flat field, no pixel-to-pixel sensitivity information is known
   #. The three-box extraction algoritm will sample a different quantity of flux and therefore apply the incorrect correction
   #. The measured amount of detected flux contained in the PSF changes due to the intrapixel sensitivity.

Seeing as it is unrealistic to perform a flat-field at every single instrument position, a new flat-fielding technique is required. Because no single flat-field image is able to accomplish all of the necessary corrections, a two-step approach will be used. In the first step, a low-frequency/lenslet-to-lenslet variation is determined by examining the total flux difference each lenslet. In the second step, the lenslet PSF is used to divide by the lamp spectrum in order to reveal the pixel to pixel variations. Because the flexure moves the PSF to various pixels, flat-fields will have to be taken at multiple (at least two) telescope/instrument positions. The implementation of this technique in the pipeline is currently underway and will be completed prior to first light.


Using Flats in GPI Pipeline Reduction:
----------------------------------------

.. warning::
   **The division of a flat field is not currently being performed due to the issues described in the above section.**

Upon the development of new algoritms, the low-order and high-order flat field corrections should be applied to all science images. Because the flat-field data will be taken at the same time as the science observations, no flat field correction is applied when using the autoreducer. When performing the science-grade reduction of the observation, often performed using the 'Calibrated Datacube Extraction' recipe, a low and high frequency flat field correction will be applied. Typically, these flat-fields will be obtained automatically from the :ref:`Calibration Database <calibdb>` based on the closest-in-time flat correction. There are no significant user-selectable options for this step to be concerned with.

Creating Calibrations:
-----------------------
**Calibration DB File Type:** Flat Field

**File Suffix:** flat

**Generate with Recipe:** 'Flat-field Extraction' (spectral mode), 'Create Polarized Flat-field' (polarimetry mode)

To produce the currently available flat fields that can only be used with flats obtained at the same flexure position, take a set of flat field observations in desired mode and filter. Reduce with the appropriate recipe. 


What to Watch Out For
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. note::
   This section will be completed upon implementation of the new flat-fielding alogorithm


Similar to dark frames, flat field frames will also exhibit striping and microphonics, but because there is structure throughout the entire image, the standard destriping algorithms (:ref:`Aggressive destripe assuming there is no signal in the image. (for darks only) <Aggressivedestripeassumingthereisnosignalintheimage.(fordarksonly)>` and :ref:`Destripe science frame <Destripescienceframe>`) cannot be applied (see section :doc:`destriping_and_microphonics` for details). The consequence of this is that the detector noise in flat-fields will be significantly higher than science frames. However, because of the large signal-to-noise in the images, the detector induced noise is expected to be negligible.
