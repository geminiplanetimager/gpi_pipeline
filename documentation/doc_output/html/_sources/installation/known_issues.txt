.. _known_issues:

Known Issues
####################


This page summarizes current known issues and imperfections to be on the lookout for. Many of these may be
improved in future versions of this software. 


As of version 1.1:

 * The location of spectra on the IFS shift due to flexure inside the spectrograph as its orientation with
   respect to gravity changes. This includes both a fairly repeatable elevation-dependent component (generally less 
   than 1 pixel in size) and occasional irregular "jumps" of up to perhaps 2 pixels. The data pipeline does not yet
   robustly automatically determine these shifts, and some manual adjustment of spectral positions is often necessary.
   See :ref:`this page <ifs_flexure>` for more details.
 * Flat fielding is not yet handled well (or at all, depending on which recipe is selected). This is because of 
   the difficulty in separating contributions from the lenslet array and detector flat fields, since there is no way to
   illuminate the detector itself with flat illumination. Improved algorithms to separate these components are under
   development. In the mean time, tests indicate that the effect of neglecting flat field corrections entirely is generally
   a < 5% (1 sigma) photometric uncertainty. More details can be found :ref:`here <processing_step_by_step_flat_fielding_lenslets>` and :ref:`here <processing_step_by_step_flat_fielding_detector>`.
 * Instrumental polarization from the telescope and GPI's own optics is not yet characterized in detail, but appears to be small (no more than a few percent).
 * Spectral and polarimetric datacube assembly use fairly simple (but very robust) apertures, a 3x1 pixel box in 
   spectral mode and a 5x5 box in polarization mode. We expect to produce datacubes with reduced systematics via
   "second generation" algorithms making use of high resolution microlens PSFs, which are currently in development. 
 * Wavelength calibration in each filter is treated independently, with separate linear wavelength solutions fit
   to each lenslet in each band. This provides calibration accuracy better than 1% after flexure has been compensated; 
   but we can probably eventually do even better via a polynomial wavelength solution simultaneously fit across
   the entire wavelength range Y-K2. 


