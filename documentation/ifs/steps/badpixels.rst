.. _processing_step_by_step_badpixels:

Bad Pixels
=======================

.. seealso:: 

        Further information may be found in `Ingraham et al. 2014 "Gemini Planet Imager Observational Calibrations II:
        Detector Performance and Characterization" <http://arxiv.org/abs/1407.2302>`_



Observed Effect and Relevant Physics:
---------------------------------------

Detectors are not perfect. There are several ways in which pixels can be non-operable. "Cold" pixels have low or zero sensitivity to photons, while "Hot" pixels have anomalously high dark current. While all pixels become nonlinear near saturation, some pixels show nonlinear behavior at much lower count levels. 


Pipeline Processing:
---------------------

When processing science data, the GPI pipeline identifies bad pixels based on precomputed maps of their locations, and attempts to mitigate them by interpolating the values. Creating bad pixel maps is discussed below. 

The repair of bad pixels is done using the primitive :ref:`Interpolatebadpixelsin2Dframe`. You can configure that primitive to just flag the bad pixels as unusuable (marking them as NaN, and also flagging them as bad in the DQ extension), or to interpolate the values via one of several interpolation methods. We recommend using the 2 vertical neighboring pixels for the interpolation for spectral mode. 

.. figure:: badpix_interp_comparison.png
        :width: 330pt
        :align: center
        :alt: alternate text
        :figwidth: 15cm 

        Comparison of different options for interpolating bad pixels. This plot was made by taking good pixels and applying the same interpolation methods, and evaluating how closely the interpolated values match the true value. Using the two vertical neighboring pixels works significantly better than using all 8 neighboring pixels. This is a consequence of the fact that the image is full of thousands of spectra dispersed in the vertical dimension. Pixels adjacent horizontally are offset in the cross-dispersion direction and won't be that close in values for interpolation.




Creating Calibrations:
-----------------------

**Calibration DB File Type:**  Bad pixel maps

**File Suffix:** coldbadpix, hotpix, nonlinearbadpix, badpix

**Generate with Recipe:**  Several. Generate Hot Bad Pixel Map from Darks, Generate Cold Bad Pixel Map from Flats, Combine Bad Pixel Maps


You'll see there are 4 different types of files related to tracking bad pixels:

 * coldbadpix: Cold Bad Pixel Map
 * hotpix: Hot Pixel Map
 * nonlinearbadpix : Nonlinear Bad Pixel Map
 * badpix: Bad Pixel Map

The ones that are named "badpix" are the final output bad pixel maps. These 
are generated from the union of one each Cold, Hot, and Nonlinear bad pixel maps. Thus, 
to generate a bad pixel map you must first generate the 
3 different individual maps, and then combine them. 


**Step 1: Hot Bad Pixels**

Maps of hot (high dark current) pixels files can be generated in the pipeline using the "Generate Hot Bad Pixel Map
from Darks" recipe. The input files should be a set of >= 10 dark exposures with identical ITIME, 
preferably ITIME > 100 s. (The longer the better...)  

The algorithm works by measuring the read noise from the standard deviation between frames, and then
locating pixels that are very significantly above this level. Specifically, the criteria for being considered a hot pixel are > 1 dark count e- per second, measured with > 5 sigma confidence.  For comparison, typical pixels have dark counts < 0.01 e-/sec for our detector. 

The Data Parser, if ran on suitable dark files, will 
automatically generate one recipe using the longest available dark sequence with >= 10 files. (If the only darks available are < 60 s in integration time, the Data Parser will not try to produce a hot pixel map.)


**Step 2: Cold Bad Pixels**

Maps of cold (non-photo-sensitive) pixels are generated using the recipe
"Generate Cold Bad Pixel Map from Flats" recipe. Finding such pixels for GPI is
more complicated than for typical instruments. Because of the lenslet array,
it's not possible to illuminate the detector with any kind of truly flat
illumination pattern. You'll always have the pattern of tens of thousands of
lenslets imprinted, with little to no illumination between them.  However, by
adding together many flat field exposures *taken using several different
filters* we can at least get illumination onto all of the pixels of the
detector.  (Though that illumination pattern is very structured rather than
flat.) We call this a "multi-filter pseudoflat".  We then take advantage of 
the translational symmetries inherent in the
lenslet array to build up a reference image that retains the spectral structure from the illumination pattern but
is smoothed over several detector pixels. By comparing individual pixels to this reference image, we can identify those that lack sensitivity. 


The "cold pixel" selection criterion is  "any pixel with < 15% normalized response measured from the summed multi-filter pseudoflat." 

The Data Parser will produce a recipe for this if given flat images in at least three different filters. (More is better)

**Step 3: Nonlinear Bad Pixels**

Every pixel shows some nonlinearity as it approaches saturation; that doesn't count as bad. 
But some pixels show *no* linear behavior at any exposure level (without being strictly hot or cold). 
It's those pixels we want to identify and exclude. 

nonlinearbadpix are an *optional* calibration. The pipeline will work fine without them. 
The required calibration file can only be generated outside of the pipeline right now, by a Python script by Marshall that
relies on looking at a flat image taken in UTR save-all-frames mode. 

*Because of this, right now the pipeline ignores the "only use calibrations from the same cooldown"
restriction for nonlinear bad pixel files - that one existing nonlinear bad pixel map can automatically be
used regardless of date.*

**Step 4: Combining the above**

This part's easy. Just run the 'Combine Bad Pixel Maps' recipe. Feed it as
input data *any* raw GPI file. The contents of that file don't actually matter, all that's used is the date. 
Based on that date, the data pipeline will 
automatically retrieve the best available (closest in time) hot, cold, and (optionally) nonlinear bad pixel
maps from the calibration database, and produce a combined file that will be
saved into the calibration directory. 

The Data Parser will produce a recipe for this if either the Hot Pixel or Cold Pixel recipes mentioned above are produced. 


Relevant GPI team members
------------------------------------
Marshall Perrin, Patrick Ingraham, Jeff Chilcote


