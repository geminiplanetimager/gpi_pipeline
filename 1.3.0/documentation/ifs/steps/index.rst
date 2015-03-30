.. _processing_step_by_step:


Processing GPI Data, Step by Step
===================================

Let's consider in turn each major topic that must be addressed during the
processing of GPI data. 

.. note::
        *Our goal here is not to document pipeline software (though that will be discussed) but rather to document our understanding of the properties and performance of the instrument itself, in terms of their effects on data processing. This document is not intended as a complete guide to achieving science-grade calibrations of your GPI science data! Not yet anyway. For now this is just a first draft discussion of what the different calibration files are, why they are required, and how you might go about generating them.*


In many cases, the Data Parser will automatically generate a good set of recipes for reducing some/all of your calibration files.

This page takes the alternate approach, of describing what you need to know in order to perform the process yourself, understand how it all works, etc. 


.. caution::
        This documentation is still incomplete and a work in progress!


.. toctree::
   :maxdepth: 1

   darks.rst
   thermal_background.rst
   badpixels.rst
   destriping_and_microphonics.rst
   nonlinearity.rst
   persistence.rst
   flat_fielding_detector.rst
   flat_fielding_lenslets.rst
   wavelength_calibration.rst
   flexure.rst
   datacube_extraction.rst
   satellite_spots.rst
   distortion.rst
   photometric_calib.rst
   psf_subtraction.rst
   companion_spectra.rst
   
If you're interested in GPI polarimetry, then you should also consult :ref:`Processing GPI Data, Step by Step: Polarimetry <processing_polarimetry>`.


