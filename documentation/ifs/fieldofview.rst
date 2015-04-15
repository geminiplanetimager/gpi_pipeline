.. _ifs_fov:

Field of View and Lenslet Geometry
=====================================


.. seealso::
        For further information please see the paper `GPI Observational Calibrations V: Astrometry and Distortion by Konopacky et al. (2014) <http://arxiv.org/abs/1407.2305>`_


The lenslet spaxel (pixel) scale is estimated to be 14.14 ± 0.01 milliarcseconds/spaxel. 

Distortion is small, with an average positional residual of 0.26 pixels over the field of view, and can be corrected using a 5th order polynomial. See the :ref:`CorrectDistortion` primitive.


The orientation of north varies continuously due to field rotation but is encoded in the World Coordinate System headers for each datacube produced by the pipeline. These make use of a time-averaged parallactic angle (keyword AVPARANG) that is recomputed by the pipeline more accurately than the PAR_ANG keyword provided by Gemini. The north angle encoded in the WCS is accurate with no offset to within our current calibration measurement uncertainty. 
(For pipeline processed outputs using version 1.1 (2014A) or earlier, the north angle was offset by -1.00±0.03 degrees.   Pipeline version 1.2 (2014B) and later have compensated for this offset. See :ref:`here <version1.2.0>` for more details.)



Dependence on Filter and Prism
----------------------------------------

**Q: Does the field of view depend on which filter I choose?**

The size of the field of view is constant with wavelength, but the specific set
of lenslets that make up the FOV varies slightly with filter.  This is
because, near the edges of the FOV, the spectral dispersion
causes different lenslets to have their reimaged spectra fall off the edge of
the detector differently depending on wavelength. For instance, if you move
from say H band to K1 band, since longer wavelengths are further toward the
'bottom' of the detector, the lenslets right next to the bottom edge of the FOV in H have
their spectra fall off the detector in K1.  Conversely, a row or two of lenslets
at the top of the detector which are just off in H band instead move into the
FOV in K1. And so forth for the other filters. 
Similarly between spectral and pol modes, the set of lenslets which is imaged
onto the detector varies slightly around the edges due to the difference in
spectral dispersion between the spectral and Wollaston prisms. 

The GPI data pipeline takes these offsets into account when assembling
datacubes: *a given physical lenslet should always map to the same (x,y)
coordinates in an unrotated raw datacube regardless of filter and  spectral or polarization
modes.* For an example of this, see the HD 70931 astrometric calibrator data from 
January 2015; both components of the binary star stay fixed in detector
coordinates while the boundary of the FOV shifts slightly around them. 

A particular consequence of this is that if the Cal-IFS pointing and centering
mirrors are aligned such that the coronagraph is centered in the FOV
in spectral mode, it will not necessarily be centered in the FOV in polarization
mode. This is *not* a shift or misalignment of the coronagraph with respect to
the lenslet array, rather it's a change in which lenslets are imaged onto the
detector. In other words it's the outer boundary of the FOV which shifts around,
not the contents of the FOV. 



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


.. _ifs_fov_rotate:

Rotating Files to North Up Yourself
----------------------------------------


**Q: I want to derotate cubes to north up myself, rather than relying on the pipeline primitive or gpitv. How do I do this?**


It's a little more complicated than just rotating by the parallatic angle (``PAR_ANG`` or ``AVPARANG`` keywords) because there is also the ~ 23.5 degree rotation of the lenslet array in order to prevent overlap of the spectra in spectral mode.  Also don't forget that you have to flip the raw cubes left-to-right if you want to get east counterclockwise of north. 

The relevant code is in two places::

 pipeline/utils/gpi_update_wcs_basic.pro            This updates the WCS keywords whenever a cube is created
 pipeline/utils/gpi_rotate_cube.pro                 This is what does the actual rotation, based on those WCS keywords.

It uses ``AVPARANG`` for the time variable part, then adds in the offsets for the IFS orientation with respect to Gemini.

Note that the ``PAR_ANG`` keyword gives the instantaneous parallactic angle at
the time that the Gemini Data System saves state for the FITS header, which
occurs when the exposure is triggered (i.e. the ``PAR_ANG`` actually gives the
parallactic angle a couple seconds before the start of integration!) The GPI
pipeline computes an ``AVPARANG`` keyword that is the time-averaged parallactic
angle over the course of the exposure.  For targets that cross very close to
zenith and thus have high maximum rotation rates, ``PAR_ANG`` can be offset by
several degrees for exposures taken right at transit.  

The GPI pipeline as of version 1.3 uses ``AVPARANG`` for all astrometric and
rotation calculations, and you should too if you're doing any rotations in your
own code outside of the pipeline. 


