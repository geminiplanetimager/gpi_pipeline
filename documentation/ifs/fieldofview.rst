Field of View and Lenslet Geometry
=====================================


.. seealso::
        For further information please see the paper `GPI Observational Calibrations V: Astrometry and Distortion by Konopacky et al. (2014) <http://arxiv.org/abs/1407.2305>`_


The lenslet spaxel (pixel) scale is estimated to be 14.14 ± 0.01 milliarcseconds/spaxel.


For pipeline processed outputs as of 2014A, for datacubes that have been processed by the 'Rotate North Up' primitive,  the north angle is offset by -1.00±0.03 degrees.  A future version of the pipeline will compensate for this offset.

Distortion is small, with an average positional residual of 0.26 pixels over the field of view, and can be corrected using a 5th order polynomial. 

Polarimetry vs Spectral Modes
--------------------------------

**Q: What about the polarimetry mode? Does the pixel scale vary significantly from the nominal 0.014?**

There's not a plausible physical mechanism to change the pixel scale between the two modes, since the prism swap is downstream of the lenslet array and thus cannot in any way affect the lenslet pixel scale.  The wave plate goes into collimated space and likewise is not expected to have a big effect. 

Jason Wang checked this in March 2014 based on a binary star observed in both spectral and polarization modes, and as expected there's no evidence that the pixel scale changes between modes.  



World Coordinate System Metadata
----------------------------------------


While raw 2D files do inclue WCS keywords, these are incorrect and should not be used. The WCS system does not at present support an image of thousands of
dispersed spectra. 

Valid WCS headers are produced as part of the datacube creation process for both spectral and polarimetry modes. 



Rotating Files to North Up Yourself
----------------------------------------


**Q: I want to derotate cubes to north up myself, rather than relying on the pipeline primitive or gpitv. How do I do this?**


It's a little more complicated than just rotating by the parallatic angle (``PAR_ANG`` keyword) because there is also the ~ 24.5 degree rotation of the lenslet array in order to prevent overlap of the spectra in spectral mode.  Also don't forget that you have to flip the raw cubes left-to-right if you want to get east counterclockwise of north. 

The relevant code is in two places::

 pipeline/utils/gpi_update_wcs_basic.pro            This updates the WCS keywords whenever a cube is created
 pipeline/utils/gpi_rotate_cube.pro                 This is what does the actual rotation, based on those WCS keywords.

It does use PAR_ANG for the time variable part, then adds in the offsets for the IFS orientation with respect to Gemini.

