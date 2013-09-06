
Thermal/Sky Backgrounds
=======================

Observed Effect and Relevant Physics:
---------------------------------------

Thermal emission (from sky or telescope) becomes an important background source for wavelengths longer than 2 microns. It thus can be necessary to subtract backgrounds, particularly when reducing calibration lamp spectra. As there is no significant emission in the Y, J or H bands, no thermal subtraction is necessary. 

In a thermal background image, image artifacts include striping, microphonics, dark current/bias and possibly persistence (although this is ignored here). Because the background is merely a flux, a long exposure can be taken and then scaled to the relative exposure time and unlike darks, the pipeline is set up to do so. Thus, one set of relatively deep background observations will suffice to correct observations in the same mode but with different integration times. 

Using Thermal/Sky Backgrounds in GPI Data Reduction:
----------------------------------------------------------

The pipeline treats thermal/sky backgrounds similar to dark frames and is designed to subtract a thermal/sky background, scaled to the integration time of the science image, from K-band observations. Currently, the subtraction is done in detector space but future implementation of the calibration may be be done in cube space, in order to allow correction for flexure effects. This decision is dependent upon the adopted observing technique. This will be a function of overheads and will most-likely be determined once on-sky.

.. note::
   Currently, the GPI reduction scripts only subtracts thermal backgrounds by default for wavelength solutions. The user must manually insert the primitive into his/her reduction recipe for the correction to be applied. If the primitive is applied to a non-K-band observation, no correction is performed.

If you try to run the 'Subtract Thermal Background' primitive on a Y, J, or H file, it will just skip that step, do no subtraction, and continue with the rest of the recipe. No error is raised. 


Creating Calibrations:
-----------------------
**Generate with Recipe:** "Combine Thermal/Sky Background Images"

**Calibration DB File Type:** Background

**File Suffix:** bkgnd

To generate a background calibration, obtain a number of images of the relevant background (e.g. sky frames, or images of the dome interior with calibration lamps turned off), with as similar as possible instrument settings to your science data. Reduce these frames with the above recipe. As per usual, take enough frames to ensure a good S/N measurement.

The Data Parser does not currently automatically generate recipes for this calibration reduction.


What to Watch Out For
------------------------------

The standard processing of Thermal/Sky background images involves 3 processing steps:

1. A dark subtraction
2. A reference pixel destripe
3. Combination of 2d images

Similar to dark frames, thermal frames will also exhibit striping and microphonics, but because there is structure throughout the entire image, the standard destriping algorithms (:ref:`Aggressive destripe assuming there is no signal in the image. (for darks only) <Aggressivedestripeassumingthereisnosignalintheimage.(fordarksonly)>` and :ref:`Destripe science frame <Destripescienceframe>`) cannot be applied (see section :doc:`destriping_and_microphonics` for details). The consequence of this is that the detector noise in Thermal/Sky backgrounds will be significantly higher than science frames. 

As noted above, the current routine does not perform the sky-subtraction in cube space. A consequence of this is that sky subtractions performed at significantly different elevations will not apply the correct calibration. 
