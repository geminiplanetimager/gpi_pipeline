
Datacube Extraction
==================================

.. seealso:: 

        Further information may be found in `Maire et al. 2014 "Gemini Planet Imager Observational Calibrations IV:
        Photometric and Spectroscopic Calibration for the Integral Field Spectrograph" <http://arxiv.org/abs/1407.2304>`_


Observed Effect and Relevant Physics:
---------------------------------------

Extraction of a datacube from a raw IFS image proceeds by integrating the signal over a rectangular 1 × 3 pixel aperture centered on each pixel along the dispersion axis. The location of each
spectra in the image are given by the wavelength solution calibration. The wavelength solution gives also the value of the wavelength at the center of each pixel of integration. Once the spectra for all micro-lens locations have each been separately extracted, they are interpolated onto a common wavelength vector and assembled into a datacube.

Pipeline Processing:
---------------------

*Assemble Spectral Datacube* transforms a 2D detector image  into a 3D data cube. This routine extracts data cube from an image using spatial summation along the dispersion axis 

*Interpolate Wavelength Axis* interpolates datacube to have each slice at the same wavelength. This is a necessary step of creating datacubes in spectral mode and should always be used right after Assemble Spectral Datacube. It will also adds wavelength keywords to the FITS header of the reduced datacube.

The output is a spectral datacube with slices at a regular wavelength sampling with a 'spdc' suffix on its filename.

These two primitives won't work if the wavelength solution has not been loaded first using "Load Wavelength Calibration".

Creating Calibrations:
-----------------------
This uses the wavelength calibration files, so see the pages for that task.

Relevant GPI team members
------------------------------------
Jerome Maire, Zack Draper, Schuyler Wolff, Marshall Perrin
