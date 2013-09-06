.. _primitives:

Primitives, Listed by Category
==============================




This page documents all available pipeline primitives, currently 107 in total. 

First we list the available primitives in each mode, and below provide the detailed documentation including the
parameter arguments for each. 

Primitives each have an "**order**", which is a floating point number that defines the *default* ordering when added to a recipe. Smaller numbers come earlier in the execution sequence. You can change the order arbitrarily in the Recipe Editor of course. Notionally, orders <2 are actions on 2D files, orders between 2-4 are actions on datacubes, and orders > 4 are actions on entire observation sequences, but these are not strictly enforced.

(*Note: For simplicity, some engineering and software testing related primitives not intended for end users are not listed in the following tables.*)

:ref:`SpectralScience`  
:ref:`PolarimetricScience`  
:ref:`Calibration`  

.. _SpectralScience:

SpectralScience
---------------

====== ======================================================================================================================================================================== =
Order  Primitives relevant to SpectralScience     (49 total)
====== ======================================================================================================================================================================== =
 0.01  :ref:`Display raw data with GPItv <DisplayrawdatawithGPItv>`
 0.50  :ref:`Load Wavelength Calibration <LoadWavelengthCalibration>`
 0.90  :ref:`Checks quality of data based on FITS keywords. <ChecksqualityofdatabasedonFITSkeywords.>`
 1.10  :ref:`Subtract Dark Background <SubtractDarkBackground>`
 1.20  :ref:`Subtract Thermal/Sky Background if K band <SubtractThermal/SkyBackgroundifKband>`
 1.20  :ref:`Persistence removal of previous images <Persistenceremovalofpreviousimages>`
 1.23  :ref:`Clean Cosmic Rays <CleanCosmicRays>`
 1.25  :ref:`Apply Reference Pixel Correction <ApplyReferencePixelCorrection>`
 1.30  :ref:`Destripe science frame <Destripescienceframe>`
 1.40  :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`
 1.50  :ref:`Combine 2D images <Combine2Dimages>`
 1.51  :ref:`Combine 2D images and save as Thermal/Sky Background <Combine2DimagesandsaveasThermal/SkyBackground>`
 1.90  :ref:`Shift 2D Image <Shift2DImage>`
 1.99  :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
 2.00  :ref:`Assemble Spectral Datacube (bp) <AssembleSpectralDatacube(bp)>`
 2.00  :ref:`Assemble Spectral Datacube <AssembleSpectralDatacube>`
 2.00  :ref:`Assemble Datacube <AssembleDatacube>`
 2.10  :ref:`Noise and Flux Analysis <NoiseandFluxAnalysis>`
 2.20  :ref:`Divide by Spectral Flat Field <DividebySpectralFlatField>`
 2.30  :ref:`Interpolate Wavelength Axis <InterpolateWavelengthAxis>`
 2.44  :ref:`Measure satellite spot locations <Measuresatellitespotlocations>`
 2.44  :ref:`Correct GPI distortion <CorrectGPIdistortion>`
 2.45  :ref:`Measure satellite spot peak fluxes <Measuresatellitespotpeakfluxes>`
 2.45  :ref:`Load Satellite Spot locations <LoadSatelliteSpotlocations>`
 2.50  :ref:`Divide spectral data by telluric transmission <Dividespectraldatabytellurictransmission>`
 2.50  :ref:`Measure telluric transmission <Measuretellurictransmission>`
 2.51  :ref:`Extract one spectrum via aperture photometry <Extractonespectrumviaaperturephotometry>`
 2.51  :ref:`Calibrate Photometric Flux and save convertion in DB <CalibratePhotometricFluxandsaveconvertioninDB>`
 2.51  :ref:`Calibrate Photometric Flux of extented object <CalibratePhotometricFluxofextentedobject>`
 2.51  :ref:`Extract one spectrum, plots <Extractonespectrum,plots>`
 2.51  :ref:`Calibrate Photometric Flux <CalibratePhotometricFlux>`
 2.51  :ref:`Extract telluric transmission from sat. spots <Extracttellurictransmissionfromsat.spots>`
 2.52  :ref:`Extract telluric transmission from datacube <Extracttellurictransmissionfromdatacube>`
 2.60  :ref:`Collapse datacube <Collapsedatacube>`
 2.61  :ref:`Simple SSDI <SimpleSSDI>`
 2.61  :ref:`Speckle alignment <Specklealignment>`
 2.70  :ref:`Measure the contrast <Measurethecontrast>`
 2.70  :ref:`Plot the satellite spot locations vs. the expected location from wavelength scaling <Plotthesatellitespotlocationsvs.theexpectedlocationfromwavelengthscaling>`
 2.80  :ref:`KLIP algorithm noise reduction <KLIPalgorithmnoisereduction>`
 2.90  :ref:`Update World Coordinates <UpdateWorldCoordinates>`
 3.90  :ref:`Rotate Field of View Square <RotateFieldofViewSquare>`
 3.90  :ref:`Rotate North Up <RotateNorthUp>`
 4.00  :ref:`Accumulate Images <AccumulateImages>`
 4.10  :ref:`Basic ADI <BasicADI>`
 4.11  :ref:`ADI with LOCI <ADIwithLOCI>`
 4.30  :ref:`Simple SSDI of median ADI residual <SimpleSSDIofmedianADIresidual>`
 4.50  :ref:`Median ADI data-cubes <MedianADIdata-cubes>`
 4.50  :ref:`Combine 3D cubes <Combine3Dcubes>`
10.00  :ref:`Save Output <SaveOutput>`
====== ======================================================================================================================================================================== =



.. _PolarimetricScience:

PolarimetricScience
-------------------

====== ======================================================================================================================================================================== =
Order  Primitives relevant to PolarimetricScience     (31 total)
====== ======================================================================================================================================================================== =
 0.01  :ref:`Display raw data with GPItv <DisplayrawdatawithGPItv>`
 0.51  :ref:`Load Polarimetry Spot Calibration <LoadPolarimetrySpotCalibration>`
 0.52  :ref:`Load Instrumental Polarization Calibration <LoadInstrumentalPolarizationCalibration>`
 0.90  :ref:`Checks quality of data based on FITS keywords. <ChecksqualityofdatabasedonFITSkeywords.>`
 1.10  :ref:`Subtract Dark Background <SubtractDarkBackground>`
 1.20  :ref:`Subtract Thermal/Sky Background if K band <SubtractThermal/SkyBackgroundifKband>`
 1.20  :ref:`Persistence removal of previous images <Persistenceremovalofpreviousimages>`
 1.23  :ref:`Clean Cosmic Rays <CleanCosmicRays>`
 1.25  :ref:`Apply Reference Pixel Correction <ApplyReferencePixelCorrection>`
 1.30  :ref:`Destripe science frame <Destripescienceframe>`
 1.40  :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`
 1.50  :ref:`Combine 2D images <Combine2Dimages>`
 1.51  :ref:`Combine 2D images and save as Thermal/Sky Background <Combine2DimagesandsaveasThermal/SkyBackground>`
 1.90  :ref:`Shift 2D Image <Shift2DImage>`
 1.99  :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
 2.00  :ref:`Assemble Datacube <AssembleDatacube>`
 2.00  :ref:`Assemble Polarization Cube <AssemblePolarizationCube>`
 2.10  :ref:`Noise and Flux Analysis <NoiseandFluxAnalysis>`
 2.44  :ref:`Correct GPI distortion <CorrectGPIdistortion>`
 2.51  :ref:`Calibrate Photometric Flux - Polarimetry <CalibratePhotometricFlux-Polarimetry>`
 2.60  :ref:`Collapse datacube <Collapsedatacube>`
 2.70  :ref:`Plot the satellite spot locations vs. the expected location from wavelength scaling <Plotthesatellitespotlocationsvs.theexpectedlocationfromwavelengthscaling>`
 2.70  :ref:`Measure the contrast <Measurethecontrast>`
 2.90  :ref:`Update World Coordinates <UpdateWorldCoordinates>`
 3.50  :ref:`Divide by Polarized Flat Field <DividebyPolarizedFlatField>`
 3.90  :ref:`Rotate Field of View Square <RotateFieldofViewSquare>`
 3.90  :ref:`Rotate North Up <RotateNorthUp>`
 4.00  :ref:`Accumulate Images <AccumulateImages>`
 4.40  :ref:`Combine Polarization Sequence <CombinePolarizationSequence>`
 4.50  :ref:`Combine 3D cubes <Combine3Dcubes>`
10.00  :ref:`Save Output <SaveOutput>`
====== ======================================================================================================================================================================== =



.. _Calibration:

Calibration
-----------

====== ========================================================================================================================== =
Order  Primitives relevant to Calibration     (56 total)
====== ========================================================================================================================== =
 0.01  :ref:`Display raw data with GPItv <DisplayrawdatawithGPItv>`
 0.50  :ref:`Load Wavelength Calibration <LoadWavelengthCalibration>`
 0.51  :ref:`Load Polarimetry Spot Calibration <LoadPolarimetrySpotCalibration>`
 0.52  :ref:`Load Instrumental Polarization Calibration <LoadInstrumentalPolarizationCalibration>`
 0.90  :ref:`Checks quality of data based on FITS keywords. <ChecksqualityofdatabasedonFITSkeywords.>`
 1.10  :ref:`Subtract Dark Background <SubtractDarkBackground>`
 1.20  :ref:`Persistence removal of previous images <Persistenceremovalofpreviousimages>`
 1.20  :ref:`Subtract Thermal/Sky Background if K band <SubtractThermal/SkyBackgroundifKband>`
 1.23  :ref:`Clean Cosmic Rays <CleanCosmicRays>`
 1.25  :ref:`Apply Reference Pixel Correction <ApplyReferencePixelCorrection>`
 1.30  :ref:`Find Bad pixels from darks or qe map <FindBadpixelsfromdarksorqemap>`
 1.30  :ref:`Destripe science frame <Destripescienceframe>`
 1.40  :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`
 1.50  :ref:`Combine 2D images <Combine2Dimages>`
 1.51  :ref:`Combine 2D images and save as Thermal/Sky Background <Combine2DimagesandsaveasThermal/SkyBackground>`
 1.70  :ref:`Measure Wavelength Calibration <MeasureWavelengthCalibration>`
 1.73  :ref:`Measure locations of Emission Lines <MeasurelocationsofEmissionLines>`
 1.80  :ref:`Measure Polarization Spot Calibration <MeasurePolarizationSpotCalibration>`
 1.80  :ref:`Measure Polarization Spot Calibration (parallelized) <MeasurePolarizationSpotCalibration(parallelized)>`
 1.90  :ref:`Shift 2D Image <Shift2DImage>`
 1.99  :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
 2.00  :ref:`Assemble Polarization Cube <AssemblePolarizationCube>`
 2.00  :ref:`Assemble Undispersed Image <AssembleUndispersedImage>`
 2.00  :ref:`Assemble Spectral Datacube <AssembleSpectralDatacube>`
 2.00  :ref:`Assemble Datacube <AssembleDatacube>`
 2.10  :ref:`Noise and Flux Analysis <NoiseandFluxAnalysis>`
 2.20  :ref:`Divide by Spectral Flat Field <DividebySpectralFlatField>`
 2.25  :ref:`Remove Flat Lamp spectrum <RemoveFlatLampspectrum>`
 2.30  :ref:`Interpolate Wavelength Axis <InterpolateWavelengthAxis>`
 2.44  :ref:`Measure GPI distortion from grid pattern <MeasureGPIdistortionfromgridpattern>`
 2.44  :ref:`Measure satellite spot locations <Measuresatellitespotlocations>`
 2.44  :ref:`Measure satellite spot locations with GPItv <MeasuresatellitespotlocationswithGPItv>`
 2.45  :ref:`Measure satellite spot peak fluxes <Measuresatellitespotpeakfluxes>`
 2.50  :ref:`Divide spectral data by telluric transmission <Dividespectraldatabytellurictransmission>`
 2.52  :ref:`Measure satellite spot flux ratios from unocculted image <Measuresatellitespotfluxratiosfromunoccultedimage>`
 2.60  :ref:`Calibrate astrometry from binary (using separation and PA) <Calibrateastrometryfrombinary(usingseparationandPA)>`
 2.60  :ref:`Collapse datacube <Collapsedatacube>`
 2.61  :ref:`Calibrate astrometry from binary (using 6th orbit catalog) <Calibrateastrometryfrombinary(using6thorbitcatalog)>`
 2.90  :ref:`Update World Coordinates <UpdateWorldCoordinates>`
 3.20  :ref:`Normalize polarimetry flats <Normalizepolarimetryflats>`
 3.50  :ref:`Divide by Polarized Flat Field <DividebyPolarizedFlatField>`
 4.00  :ref:`Accumulate Images <AccumulateImages>`
 4.01  :ref:`Combine 2D dark images <Combine2Ddarkimages>`
 4.01  :ref:`create Low Frequency Flat 2D <createLowFrequencyFlat2D>`
 4.01  :ref:`Find Hot Pixels from a set of Darks <FindHotPixelsfromasetofDarks>`
 4.01  :ref:`Find Cold Pixels from a set of Flats <FindColdPixelsfromasetofFlats>`
 4.01  :ref:`Create a microphonics noise model. <Createamicrophonicsnoisemodel.>`
 4.01  :ref:`Create Bad Pixel Map from text list of pixels <CreateBadPixelMapfromtextlistofpixels>`
 4.02  :ref:`Generate Combined Bad Pixel Map <GenerateCombinedBadPixelMap>`
 4.20  :ref:`Populate Shifts vs Elevation Table <PopulateShiftsvsElevationTable>`
 4.20  :ref:`Combine Wavelength Calibrations locations <CombineWavelengthCalibrationslocations>`
 4.20  :ref:`Combine Wavelength Calibrations <CombineWavelengthCalibrations>`
 4.40  :ref:`Combine Polarization Sequence <CombinePolarizationSequence>`
 4.50  :ref:`Combine 3D cubes <Combine3Dcubes>`
 9.90  :ref:`Set Calibration Type <SetCalibrationType>`
10.00  :ref:`Save Output <SaveOutput>`
====== ========================================================================================================================== =


Primitive Detailed Documentation
==================================


.. index::
    single:Display raw data with GPItv

.. _DisplayrawdatawithGPItv:

Display raw data with GPItv
---------------------------

 Display, with GPItv, raw data to be processed  

**Category**:  ALL, HIDDEN      **Order**: 0.01

**Inputs**:  A raw 2D file.

**Outputs**:  No change to data

**Notes**:

.. code-block:: idl


 		Display in GPITV the current raw image, before any processing


 KEYWORDS:
 	gpitv=		session number for the GPITV window to display in.
 				set to '0' for no display, or >=1 for a display.




 HISTORY:
 	Originally by Jerome Maire 2007-11
   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
	  2008-06-06 JM: adapted to pipeline inputs
	  2009-04-15 MDP: Documentation updated
   2009-09-17 JM: added DRF parameters

**Parameters**:

=======  ======  =========  =========  ======================================================================
   Name    Type      Range    Default                                                             Description
=======  ======  =========  =========  ======================================================================
  gpitv     int    [0,500]          1    1-500: choose gpitv session for displaying output, 0 for no display 
=======  ======  =========  =========  ======================================================================


**IDL Filename**: displayrawimage.pro


.. index::
    single:Load Wavelength Calibration

.. _LoadWavelengthCalibration:

Load Wavelength Calibration
---------------------------

 Reads a wavelength calibration file from disk. This primitive is required for any data-cube extraction.

**Category**:  SpectralScience,Calibration      **Order**: 0.5

**Inputs**: Not specified

**Outputs**:  none; wavecal is loaded into memory

**Notes**:

.. code-block:: idl


 	Reads a wavelength calibration file from disk.
 	The wavelength calibration is stored using pointers into the common block.



 HISTORY:
 	Originally by Jerome Maire 2008-07
 	Documentation updated - Marshall Perrin, 2009-04
   2009-09-02 JM: hist added in header
   2009-09-17 JM: added DRF parameters
   2010-03-15 JM: added automatic detection
   2010-08-19 JM: fixed bug which created new pointer everytime this primitive was called
   2010-10-19 JM: split HISTORY keyword if necessary
   2013-03-28 JM: added manual shifts of the wavecal
   2013-04		   manual shifts code moved to new update_shifts_for_flexure
   2013-07010 MP: Documentation update and code cleanup

**Parameters**:

=================  ========  =======  ===========  ================================================================
             Name      Type    Range      Default                                                       Description
=================  ========  =======  ===========  ================================================================
  CalibrationFile    wavcal     None    AUTOMATIC    Filename of the desired wavelength calibration file to be read
=================  ========  =======  ===========  ================================================================


**IDL Filename**: readwavcal.pro


.. index::
    single:Load Polarimetry Spot Calibration

.. _LoadPolarimetrySpotCalibration:

Load Polarimetry Spot Calibration
---------------------------------

 Reads a pol spot calibration file from disk. This primitive is required for any polarimetry data-cube extraction.

**Category**:  PolarimetricScience,Calibration      **Order**: 0.51

**Inputs**: Not specified

**Outputs**:  none

**Notes**:

.. code-block:: idl


   Reads a polarimetry spot calibration file from disk.
   The spot calibration is stored using pointers into the common block.



 HISTORY:
   2013-01-28 MMB: Adapted to pol extraction (based on readwavcal.pro)
   2013-02-07 MP:  Updated logging and docs a little bit.
                   Added efficiently not reloading the same file multiple times.
   2013-06-04 JBR: shifts for flexure code is now moved to
                   update_shifts_for_flexure.pro and commented out here.
   2013-07-10 MP:  Documentation update and code cleanup.

**Parameters**:

=================  ========  =======  ===========  ================================================================
             Name      Type    Range      Default                                                       Description
=================  ========  =======  ===========  ================================================================
  CalibrationFile    polcal     None    AUTOMATIC    Filename of the desired wavelength calibration file to be read
=================  ========  =======  ===========  ================================================================


**IDL Filename**: readpolcal.pro


.. index::
    single:Load Instrumental Polarization Calibration

.. _LoadInstrumentalPolarizationCalibration:

Load Instrumental Polarization Calibration
------------------------------------------

 

**Category**:  PolarimetricScience,Calibration      **Order**: 0.52

**Inputs**: Not specified

**Outputs**: 

**Notes**:

.. code-block:: idl





 HISTORY:
 	2010-05-22 MDP: started
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

=================  =========  =======  ===========  ===================================================================
             Name       Type    Range      Default                                                          Description
=================  =========  =======  ===========  ===================================================================
  CalibrationFile    instpol     None    AUTOMATIC    Filename of the desired instrumental polarization file to be read
=================  =========  =======  ===========  ===================================================================


**IDL Filename**: load_instpol.pro


.. index::
    single:Checks quality of data based on FITS keywords.

.. _ChecksqualityofdatabasedonFITSkeywords.:

Checks quality of data based on FITS keywords.
----------------------------------------------

 Check quality of data using keywords. Appropriate action for bad quality data is user-defined. 

**Category**:  ALL      **Order**: 0.9

**Inputs**:  2D image file

**Outputs**:  No change in data; reduction either continues or is terminated.

**Notes**:

.. code-block:: idl


   This routine looks at various FITS header keywords to
   assess whether the data should be considered usable or not.

   The keywords checked include GPIHEALT, AVGRNOT, RMSERR.
   You can set the acceptable minimum data quality with the r0 and rmserr
   parameters to this primitive.

   If a file of unacceptable quality is detected, the action taken will
   be determined by the "action" parameter:
     0. Alert the user with a message printed to screen
        but allow reduction to continue
     1. Halt the reduction and fail the receipe.

  TODO: implement pop-up window for alerts rather than just
        printing a message on screen


 GEM/GPI KEYWORDS:AVRGNOT,GPIHEALT,RMSERR


 HISTORY:
   JM 2010-10 : created
   MP 2013-01 : Docs updated
   2013-07-11 MP: Documentation cleanup. Rename 'control_data_quality' -> 'check_data_quality'



**Parameters**:

========  =======  ==========  =========  ==========================================================
    Name     Type       Range    Default                                                 Description
========  =======  ==========  =========  ==========================================================
  Action      int      [0,10]          1    0:Simple alert and continue reduction, 1:Reduction fails
      r0    float       [0,2]       0.08                        critical r0 [m] at lambda=0.5microns
  rmserr    float    [0,1000]        10.                   Critical rms wavefront error in microns. 
========  =======  ==========  =========  ==========================================================


**IDL Filename**: check_data_quality.pro


.. index::
    single:Subtract Dark Background

.. _SubtractDarkBackground:

Subtract Dark Background
------------------------

 Subtract a dark frame. 

**Category**:  ALL      **Order**: 1.1

**Inputs**:  raw 2D image file

**Outputs**:  2D image corrected for dark current      **Output Suffix**:  'darksub'

**Notes**:

.. code-block:: idl


    Look up from the calibration database what the best dark file of
    the correct time is, and subtract it.

    If no dark file of the correct time is found, then don't do any
    subtraction at all, just return the input data.



 ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.


 HISTORY:
 	Originally by Jerome Maire 2008-06
 	2009-04-20 MDP: Updated to pipeline format, added docs.
 				    Some code lifted from OSIRIS subtradark_000.pro
   2009-09-02 JM: hist added in header
   2009-09-17 JM: added DRF parameters
   2010-10-19 JM: split HISTORY keyword if necessary
   2012-07-20 MP: added DRPDARK keyword
   2012-12-13 MP: Remove "Sky" from primitve discription since it's inaccurate
   2013-07-11 MP: rename 'applydarkcorrection' -> 'subtract_dark_background' for consistency


**Parameters**:

=================  ==========  =========  ===========  ===================================================================
             Name        Type      Range      Default                                                          Description
=================  ==========  =========  ===========  ===================================================================
  CalibrationFile    filename       None    AUTOMATIC                                        Name of dark file to subtract
             Save         int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv         int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ==========  =========  ===========  ===================================================================


**IDL Filename**: subtract_dark_background.pro


.. index::
    single:Persistence removal of previous images

.. _Persistenceremovalofpreviousimages:

Persistence removal of previous images
--------------------------------------

 Determines/Removes persistence of previous images

**Category**:  ALL      **Order**: 1.2

**Inputs**:  Raw or destriped 2D image

**Outputs**:  2D image corrected persistence of previous non-saturated images      **Output Suffix**:  '-nopersis'

**Notes**:

.. code-block:: idl


 The removal of persistence from previous non-saturated images
 incorporates a model developed for Hubble Space Telescopes Wide
 Field Camera 3 (WFC3,
 www.stsci.edu/hst/wfc3/ins_performance/persistence).
 Persistence is proportional to the intensity of the illuminating
 source, and is observed to fade exponentially with time. The
 parameters of the mathematical model for the persistence, found
 in the pipeline's configuration directory were determined
 during integration and test at UCSC.

 This primitive searches for all files in the raw data directory
 taken within 600 seconds (10 min) of the beginning of the exposure
 of interest. It then calculates the persistence from each image,
 using the maximum of the stack, and subtracts it from the
 frame. Note that if the detector is exposed to light, but no
 exposures are being taken, persistence will still build up on the
 detector that cannot be subtracted.

 Ideally, this program should be run after the destriping algorithm
 as readnoise does not induce persistence. However, due to limitation
 that a pipeline primitive cannot call another primitive, this has
 not been implemented. Future developement will involve moving the
 destriping algorithm into a idl function, and then calling the
 function from the destriping primitive. This will enable the ability
 for this primitive to destripe the previous images. The user should
 note that the destriping is at a level that is low enough to not
 leave a significant persistence, so this detail will not
 significantly affect science data.

 At this time, the persistence is removed at the ~75% level due to
 inaccuracies in the model caused by an insufficient time sampling of
 the initial falloff and readnoise. A new dataset will be taken prior to shipping,
 and new model parameters will be derived prior to commissioning.


 Requires the persistence_model_parameters.fits calibration file.



 HISTORY:

       Wed May 22 15:11:10 2013, LAB <LAB@localhost.localdomain>


   2013-05-14 PI: Started


**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    persis       None    AUTOMATIC                Filename of the persistence_parameter file to be read
             Save       int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: persistence_correction.pro


.. index::
    single:Subtract Thermal/Sky Background if K band

.. _SubtractThermal/SkyBackgroundifKband:

Subtract Thermal/Sky Background if K band
-----------------------------------------

 Subtract a dark frame. 

**Category**:  ALL      **Order**: 1.2

**Inputs**:  2D image file

**Outputs**:  2D image file, unchanged if YJH, background subtracted if K1 or K2.      **Output Suffix**:  'bkgndsub'

**Notes**:

.. code-block:: idl


  Subtract thermal background emission, for K band data only

	** special note: **

	This is a new kind of "data dependent optional primitive". If the filter of
	the current data is YJH, return without doing *anything*, even logging the
	start/end of this primitive.  It becomes a complete no-op for non-K-band
	cases.

 Algorithm:

	Get the best available thermal background calibration file from CalDB
	Scale it to current exposure time
	Subtract it.
   The name of the calibration file used is saved to the DRPBKGND header keyword.

 ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.





 HISTORY:
   2012-12-13 MP: Initial implementation
   2013-01-16 MP: Documentation cleanup.

**Parameters**:

=================  ======  =========  ===========  ===================================================================
             Name    Type      Range      Default                                                          Description
=================  ======  =========  ===========  ===================================================================
  CalibrationFile    dark       None    AUTOMATIC                          Name of thermal background file to subtract
             Save     int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv     int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ======  =========  ===========  ===================================================================


**IDL Filename**: subtract_thermal_bkgnd_if_k.pro


.. index::
    single:Clean Cosmic Rays

.. _CleanCosmicRays:

Clean Cosmic Rays
-----------------

 Placeholder for cosmic ray rejection (if needed; not currently implemented!)

**Category**:  ALL      **Order**: 1.23

**Inputs**: Not specified

**Outputs**: Not specified

**Notes**:

.. code-block:: idl

   Placeholder; des not actually do anything yet.
   Empirically, cosmic rays do not appear to be a significant noise source
   for the GPI IFS. It's a substrate-removed H2RG so the level is quite low.



 HISTORY:
 2010-01-28 MDP: Created Templae.
 2011-07-30 MDP: Updated for multi-extension FITS

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          0                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_cosmicrays.pro


.. index::
    single:Apply Reference Pixel Correction

.. _ApplyReferencePixelCorrection:

Apply Reference Pixel Correction
--------------------------------

 Subtract channel bias levels using H2RG reference pixels.

**Category**:  ALL      **Order**: 1.25

**Inputs**:  2D image file

**Outputs**:  2D image corrected for background using reference pixels      **Output Suffix**:  'refpixcorr'

**Notes**:

.. code-block:: idl


 	Correct for fluctuations in the bias/dark level using the rows of
 	reference pixels in the H2RG detectors.
   Algorithm choices include:
    1) simple_channels		in this case, just use the median of each
    					    vertical channel to remove offsets between
    					    the channels
    2) simple_horizontal	take the median of the 8 ref pix for each row,
    						and subtract that from each row.
    3) interpolating		in this case, use James Larkin's interpolation
    						algorithm to remove linear variation with time
    						in the horizontal direction

 	See discussion in section 3.1 of Rauscher et al. 2008 Prof SPIE 7021 p 63.



 ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.


 HISTORY:
 	Originally by Jerome Maire 2008-06
 	2009-04-20 MDP: Updated to pipeline format, added docs.
 				    Some code lifted from OSIRIS subtradark_000.pro
   2009-09-17 JM: added DRF parameters
   2012-07-27 MP: Added Method parameter, James Larkin's improved algorithm
   2012-10-14 MP: debugging and code cleanup.

**Parameters**:

==================  ======  ==============================  ==============  ===================================================================
              Name    Type                           Range         Default                                                          Description
==================  ======  ==============================  ==============  ===================================================================
              Save     int                           [0,1]               0                                1: save output on disk, 0: don't save
             gpitv     int                         [0,500]               0    1-500: choose gpitv session for displaying output, 0: no display 
  before_and_after     int                           [0,1]               0                Show the before-and-after images for the user to see?
            Method    enum    SIMPLE_CHANNELS|INTERPOLATED    INTERPOLATED                           Algorithm for reference pixel subtraction.
==================  ======  ==============================  ==============  ===================================================================


**IDL Filename**: applyrefpixcorrection.pro


.. index::
    single:Destripe science frame

.. _Destripescienceframe:

Destripe science frame
----------------------

  Subtract detector striping using measurements between the microspectra

**Category**:  SpectralScience,Calibration, PolarimetricScience      **Order**: 1.3

**Inputs**: Not specified

**Outputs**: Not specified      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl



  Subtract horizontal striping from the background of a 2d
  raw IFS image by masking spectra and using the remaining regions to obtain a
  sampling of the striping.

  The masking can be performed by using the wavelength calibration to mask the
  spectra (recommended) or by thresholding (not recommended).

  WARNING: This destriping algorithm will not work correctly on flat fields or
  any image where there is very large amounts of signal covering the entire
  field. If called on such data, it will print a warning message and return
  without modifying the data array.

 Summary of the primitive:
 The principle of the primitive is to build models of the different source of noise you want to treat and then subtract them to the real image at the end.
 1/ mask computation
 2/ Channels offset model based on im = image => chan_offset
 3/ Microphonics computation based on im = image - chan_offset => microphonics_model
 4/ Destriping model based on im = image - chan_offset - microphonics_model => stripes
 5/ Output: imout = image - chan_offset - microphonics_model - stripes

 Destriping Algorithm Details:
    Generate a mask of where the spectra are located, based on the
      already-loaded wavelength or pol spots solutions.
    Mask out those pixels.
  Break the image up into the 32 readout channels
  Flip the odd channels to account for the alternating readout direction.
  Generate a median image across the 32 readout channels
  Smooth by 20 pixels to generate the broad variations
  mask out any pixels that are >3 sigma discrepant vs the broad variations
  Generate a better median image across the 32 readout channels post masking
  Perform some sanity checks for model validity and interpolate NaNs as needed
  Expand to a 2D image model of the detector


 OPTIONAL/EXPERIMENTAL:
  The microphonics noise attenuation can be activitated by setting the parameter remove_microphonics to 1 or 2.
  The microphonics from the image can be saved in a file using the parameter save_microphonics.
  If Plot_micro_peaks equal 'yes', then it will open 3 plot windows with the peaks aera of the microphonics in Fourier space (Before microphonics subtraction, the microphonics to be removed and the final result). Used for debugging purposes.

  If remove_microphonics = 1:
    The algorithm is always applied.

  If remove_microphonics = 2:
    The algorithm is applied only of the quantity of noise is greater than the micro_treshold parameter.
    A default empirical value of 0.01 has been set based on the experience of the author of the algorithm.
    The quantity of microphonics noise is measured with the ratio of the dot_product and the norm of the image: dot_product/sqrt(sum(abs(fft(image))^2)).
    With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.

  There are 3 implemented methods right now depending on the value of the parameter method_microphonics.

  If method_microphonics = 1:
    The microphonics noise removal is based on a fixed precomputed model. This model is the normalized absolute value of the Fourier coefficients.
    The filtering consist of diminishing the intensity of the frequencies corresponding to the noise in the image proportionaly to the dot product of the image witht the noise model.
    The phase remains unchanged.
    The filtered coefficients in Fourier space become (1-dot_product*(Amplitude_noise_model/Amplitude_image)).
    With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.

  If method_microphonics = 2:
    The frequencies around the 3 identified peaks of the microphonics noise in Fourier space are all set to zero.
    This algorithm is the best one of you are sure that there is no data in this aera but it is probably better not to use it...

  If method_microphonics = 3:
    A 2d gaussian is fitted for each of the three peaks of the microphonics noise in Fourier space and then removed.
    Only the absolute value is considered and the phase remains unchanged.
    This algorthim is not as efficient as the two others but if you don't have an accurate model, it can be better than nothing.




 HISTORY:
     Originally by Marshall Perrin, 2011-07-15
   2011-07-30 MP: Updated for multi-extension FITS
   2012-12-12 PI: Moved from Subtract_2d_background.pro
   2012-12-30 MMB: Updated for pol extraction. Included Cal file, inserted IDL version checking for smooth() function
   2013-01-16 MP: Documentation cleanup.
   2013-03-12 MP: Code cleanup, some speed enhancements by vectorization
   2013-05-28 JBR: Primitive copy pasted from the destripe_mask_spectra.pro primitive. Microphonics noise enhancement. Microphonics algorithm now applied before the destriping.

**Parameters**:

========================  ========  ======================  ===========  ===============================================================================================================================================================================
                    Name      Type                   Range      Default                                                                                                                                                                      Description
========================  ========  ======================  ===========  ===============================================================================================================================================================================
                  method    string    [threshhold|calfile]      calfile                                                                                 Find background based on image value threshhold cut, or calibration file spectra/spot locations?
          abort_fraction     float               [0.0,1.0]          0.9                                                                                 Necessary fraction of pixels in mask to continue - set at 0.9 to ensure quicklook tool is robust
  chan_offset_correction       int                   [0,1]            0                                                                                                     Tries to correct for channel bias offsets - useful when no dark is available
                fraction     float               [0.0,1.0]          0.7                                                                                                                      What fraction of the total pixels in a row should be masked
              high_limit     float                 [0,Inf]            1                                                                                                                    Pixel value where exceeding values are assigned a larger mask
            Save_stripes       int                   [0,1]            0                                                                                                                             Save the striping noise image subtracted from frame?
                 display    string                [yes|no]           no                                                                                                                             Show diagnostic before and after plots when running?
     remove_microphonics       int                   [0,2]            0    Remove microphonics noise based on a precomputed fixed model.0: not applied. 1: applied. 2: the algoritm is applied only if the measured noise is greater than micro_treshold
     method_microphonics       int                   [1,3]            0                                                                                              Method applied for microphonics 1: model projection. 2: all to zero 3: gaussian fit
         CalibrationFile     micro                    None    AUTOMATIC                                                                                                                       Filename of the desired microphonics model file to be read
        Plot_micro_peaks    string                [yes|no]           no                                                                                                                           Plot in 3d the peaks corresponding to the microphonics
       save_microphonics    string                [yes|no]           no                                                                                If remove_microphonics = 1 or (auto and micro_treshold overpassed), save the removed microphonics
          micro_treshold     float               [0.0,1.0]         0.01                                                        If remove_microphonics = 2, set the treshold. This value is sum(abs(fft(image))*abs(fft(noise_model)))/sqrt(sum(image^2))
                    Save       int                   [0,1]            0                                                                                                                                            1: Save output to disk, 0: Don't save
                   gpitv       int                 [0,500]            1                                                                                                                1-500: choose gpitv session for displaying output, 0: no display 
========================  ========  ======================  ===========  ===============================================================================================================================================================================


**IDL Filename**: destripe_mask_spectra.pro


.. index::
    single:Aggressive destripe assuming there is no signal in the image. (for darks only)

.. _Aggressivedestripeassumingthereisnosignalintheimage.(fordarksonly):

Aggressive destripe assuming there is no signal in the image. (for darks only)
------------------------------------------------------------------------------

 Subtract readout pickup noise using median across all channels.

**Category**:       **Order**: 1.3

**Inputs**:  A 2D dark image

**Outputs**:  2D image corrected for stripe noise      **Output Suffix**:  'destripe'

**Notes**:

.. code-block:: idl


 	Correct for fluctuations in the background bias level
 	(i.e. horizontal stripes in	the raw data) using a pixel-by-pixel
 	median across all channels, taking into account the alternating readout
 	directions for every other channel.

 	This provides a very high level of rejection for stripe noise, but of course
 	it assumes that there's no signal anywhere in your image. So it's only
 	good for darks.


   A second noise source that can be removed by this routine is the
   so-called microphonics noise induced by high frequency vibrational modes of
   the H2RG. This noise has a characteristic frequenct both temporally and
   spatially, which lends itself to removal via Fourier filtering. After
   destriping, the image is Fourier transformed, masked to select only the
   Fourier frequencies of interest, and transformed back to yield a model for
   the microphonics striping that can be subtracted from the data. Empirically
   this correction works quite well. Set the "remove_microphonics" option to
   enable this, and set "display" to show on screen a
   diagnostic plot that lets you see the stripe & microphonics removal in
   action.

 SEE ALSO: Destripe science frame




 HISTORY:
   2012-10-16 Patrick: fixed syntax error (function name)
   2012-10-13 MP: Started
   2013-01-16 MP: Documentation cleanup
   2012-03-13 MP: Added Fourier filtering to remove microphonics noise
   2013-04-25 MP: Improved documentation, display for microphonics removal.

**Parameters**:

=====================  ========  ==========  =========  ===================================================================
                 Name      Type       Range    Default                                                          Description
=====================  ========  ==========  =========  ===================================================================
  remove_microphonics    string    [yes|no]        yes          Attempt to remove microphonics noise via Fourier filtering?
              display    string    [yes|no]         no                 Show diagnostic before and after plots when running?
                 Save       int       [0,1]          0                                1: save output on disk, 0: don't save
                gpitv       int     [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=====================  ========  ==========  =========  ===================================================================


**IDL Filename**: destripe_for_darks.pro


.. index::
    single:Find Bad pixels from darks or qe map

.. _FindBadpixelsfromdarksorqemap:

Find Bad pixels from darks or qe map
------------------------------------

 Find hot/cold pixels from qe map. Find deviants with [Intensities gt (1 + nbdev) *  mean_value_of the frame] and [Intensities lt (1 - nbdev) *  mean_value_of the frame]. (bad pixel =1, 0 elsewhere)

**Category**:  Calibration      **Order**: 1.3

**Inputs**: Not specified

**Outputs**:       **Output Suffix**: 'qebadpix'

**Notes**:

.. code-block:: idl




 KEYWORDS:
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
   2009-07-20 JM: created
   2009-09-17 JM: added DRF parameters
   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
   2012-10-17 MP: Removed deprecated suffix= keyword


**Parameters**:

=======  =======  ===========  =========  ========================================================================
   Name     Type        Range    Default                                                               Description
=======  =======  ===========  =========  ========================================================================
  nbdev    float    [0.,100.]        0.7    Allowed maximum location fluctuation (in pixel) between adjacent mlens
   Save      int        [0,1]          1                                     1: save output on disk, 0: don't save
  gpitv      int      [0,500]          2         1-500: choose gpitv session for displaying output, 0: no display 
=======  =======  ===========  =========  ========================================================================


**IDL Filename**: gpi_find_badpixels_from_qemap.pro


.. index::
    single:Interpolate bad pixels in 2D frame

.. _Interpolatebadpixelsin2Dframe:

Interpolate bad pixels in 2D frame
----------------------------------

  Repair bad pixels by interpolating between their neighbors. Can optionally just flag as NaNs or else interpolate.

**Category**:  SpectralScience, PolarimetricScience, Calibration      **Order**: 1.4

**Inputs**:  2D image, ideally post dark subtraction and destriping

**Outputs**:  2D image with bad pixels marked or cleaned up.      **Output Suffix**: '-bpfix'

**Notes**:

.. code-block:: idl


	Interpolates between vertical (spectral dispersion) direction neighboring
	pixels to fix each bad pixel.

   Bad pixels are identified from:
   1. The pixels marked bad in the current bad pixel mask (provided in the
      CalibrationFile parameter.)
   2. Any additional pixels which are marked as bad in the image extension
      for data quality (DQ).
   3. Any pixels which are < -50 counts (i.e. are > 5 sigma negative where
      sigma is the CDS read noise for a single read). TODO: This threshhold
      should be evaluated and possibly made adjustible.

  The action taken on those bad pixels is determined from the 'method'
  parameter, which can be one of:
    'nan':   Bad pixels are just marked as NaN, with no interpolation
    'vertical': Bad pixels are repaired by interpolating over their
             immediate neighbors vertically, the pixels above and below.
             This has been shown to work well for spectral mode GPI data
             since vertical is the spectral dispersion direction.
             (The actual algorithm is a bit more complicated than this to
			  handle cases where the above and/or below pixels are themselves
			  also bad.)
    'all8':  Repair by interpolating over all 8 surrounding pixels.



	TODO: need to evaluate whether that algorithm is still a good approach for
	polarimetry mode files.

	TODO: implement Christian's suggestion of a 3D interpolation in 2D space,
	using adjacent lenslet spectra as well. See emails of Oct 18, 2012
	(excerpted below)






 HISTORY:
 	Originally by Marshall Perrin, 2012-10-18
 	2012-12-03 MP: debugging/enhancements for the case of multiple adjacent bad
 					pixels
 	2012-12-09 MP: Added support for using information in DQ extension
 	2013-01-16 MP: Documentation cleanup
 	2013-02-07 MP: Enhanced all8 interpolation to properly handle cases where
					there are bad pixels in the neighboring pixels.
   2013-04-02 JBR: Correction of a sign in the vertical algorithm when reading the bottom adjacent pixel.
   2013-04-22 JBR: In vertical algorithm, condition added if both upper and bottom pixels are good.
	2013-06-26 MP: Added better FITS history logging for the case of not having a bad pixel map.

**Parameters**:

==================  ========  =====================  ==========  ================================================================================================================
              Name      Type                  Range     Default                                                                                                       Description
==================  ========  =====================  ==========  ================================================================================================================
   CalibrationFile      None                   None        None                                                                 Filename of the desired bad pixel file to be read
            method    string    [n4n|vertical|all8]    vertical    Repair bad bix interpolating all 8 neighboring pixels, or just the 2 vertical ones, or just flag as NaN (n4n)?
              Save       int                  [0,1]           0                                                                             1: save output on disk, 0: don't save
             gpitv       int                [0,500]           1                                                 1-500: choose gpitv session for displaying output, 0: no display 
  before_and_after       int                  [0,1]           0                                     Show the before-and-after images for the user to see? (for debugging/testing)
==================  ========  =====================  ==========  ================================================================================================================


**IDL Filename**: interpolate_badpix_2d.pro


.. index::
    single:Combine 2D images

.. _Combine2Dimages:

Combine 2D images
-----------------

 Combine 2D images such as darks into a master file via mean or median. 

**Category**:  ALL      **Order**: 1.5

**Inputs**:  2D images

**Outputs**:  a single combined 2D image      **Output Suffix**:  strlowcase(method)

**Notes**:

.. code-block:: idl


  Multiple 2D images can be combined into one using either a Mean or a Median.

  TODO: more advanced combination methods. sigma-clipped mean should be
  implemented, etc.



 HISTORY:
 	 Jerome Maire 2008-10
   2009-09-17 JM: added DRF parameters
   2009-10-22 MDP: Created from mediancombine_darks, converted to use
   				accumulator.
   2010-01-25 MDP: Added support for multiple methods, MEAN method.
   2011-07-30 MP: Updated for multi-extension FITS
   2012-10-10 MP: Minor code cleanup
   2013-07-10 MP: Minor documentation cleanup


**Parameters**:

========  ======  ======================  =========  ======================================================================
    Name    Type                   Range    Default                                                             Description
========  ======  ======================  =========  ======================================================================
  Method    enum    MEAN|MEDIAN|MEANCLIP     MEDIAN    How to combine images: median, mean, or mean with outlier rejection?
    Save     int                   [0,1]          1                                   1: save output on disk, 0: don't save
   gpitv     int                 [0,500]          2       1-500: choose gpitv session for displaying output, 0: no display 
========  ======  ======================  =========  ======================================================================


**IDL Filename**: combine2dframes.pro


.. index::
    single:Combine 2D images and save as Thermal/Sky Background

.. _Combine2DimagesandsaveasThermal/SkyBackground:

Combine 2D images and save as Thermal/Sky Background
----------------------------------------------------

 Combine 2D images with measurement of thermal or sky background

**Category**:  ALL      **Order**: 1.51

**Inputs**:  2D image(s) taken with lamps off.

**Outputs**:  thermal background file, saved as calibration file      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	Generate a 2D background image for use in removing e.g. thermal emission
	from lamp images




 HISTORY:
   2012-12-13 MP: Forked from combine2dframes
   2013-07-10 MP: Minor documentation cleanup


**Parameters**:

========  ======  =============  =========  ======================================================================
    Name    Type          Range    Default                                                             Description
========  ======  =============  =========  ======================================================================
  Method    enum    MEAN|MEDIAN     MEDIAN    How to combine images: median, mean, or mean with outlier rejection?
    Save     int          [0,1]          1                                   1: save output on disk, 0: don't save
   gpitv     int        [0,500]          2       1-500: choose gpitv session for displaying output, 0: no display 
========  ======  =============  =========  ======================================================================


**IDL Filename**: combine2dbackgrounds.pro


.. index::
    single:Measure Wavelength Calibration

.. _MeasureWavelengthCalibration:

Measure Wavelength Calibration
------------------------------

 Derive wavelength calibration from an arc lamp or flat-field image.

**Category**:  Calibration      **Order**: 1.7

**Inputs**:  2D image from narrow band arclamp

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	gpi_extract_wavcal detects positions of spectra in the image with narrow
	band lamp image.

 ALGORITHM:
	gpi_extract_wavcal starts by detecting the central peak of the image.
	Next, starting with a initial value of w & P, find the nearest peak (with an increment on the microlens coordinates)
	when nearest peak has been detected, it reevaluates w & P and so forth..

 *********************************************************************************
 *
 *  IMPORTANT WARNING for future software maintainers:
 *     The complicated algorithms implemented here were originally developed
 *     assuming the dispersion direction in GPI would be horizontal. Given data
 *     orientation conventions later adopted, it became vertical. Rather than
 *     rewriting all of the following and swapping all the indices around,
 *     the images are just *transposed* as the first step of this process, and
 *     then the original horizontal algorithm applied. This leads to various
 *     complexities about index transformations. Be wary when editing the
 *     code here and keep that in mind....
 *
 *
 *********************************************************************************



 common needed:

 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP,GCALSHUT,OBSTYPE
 DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB


 HISTORY:
 	 Jerome Maire 2008-10
	  JM: nlens, w (initial guess), P (initial guess), cenx (or centrXpos), ceny (or centrYpos) as parameters
   2009-09-17 JM: added DRF parameters
   2009-12-10 JM: initiate position at 1.5microns so we can take into account several band
   2010-07-14 JM:for DRP testing, correct for DST finite spectral resolution
   2010-08-16 JM: added bad pixel map
   2011-07-14 MP: Reworked FITS keyword handling to provide more informative
         error messages in case of missing or invalid keywords.
   2011-08-02 MP: Updated for multi-extension FITS.
   2012-12-13 MP: Bad pixel map now taken from DQ extension if present.
				   Print more informative logging messages for the user
				   Various bits of code cleanup.
   2012-12-20 JM more centroid methods added

**Parameters**:

===================  ========  ==============  ===========  =====================================================================================================
               Name      Type           Range      Default                                                                                            Description
===================  ========  ==============  ===========  =====================================================================================================
              nlens       int         [0,400]          281                                                                    side length of  the  lenslet array 
          centrXpos       int        [0,2048]         1024                                   Initial approximate x-position [pixel] of central peak at 1.5microns
          centrYpos       int        [0,2048]         1024                                   Initial approximate y-position [pixel] of central peak at 1.5microns
                  w     float        [0.,10.]          4.8                      Spectral spacing perpendicular to the dispersion axis at the image center [pixel]
                  P     float        [-7.,7.]         -1.8      Ratio of spectral offset parallel to dispersion over spectral spacing perpendicular to dispersion
  emissionlinesfile    string            None    AUTOMATIC                                                                                File of emission lines.
  wav_of_centrXYpos       int           [1,2]            2     1 if centrX-Ypos is the smallest-wavelength peak of the band; 2 if centrX-Ypos refer to 1.5microns
             maxpos     float        [-7.,7.]           2.                                 Allowed maximum location fluctuation (in pixel) between adjacent mlens
            maxtilt     float    [-360.,360.]          10.                                    Allowed maximum tilt fluctuation (in degree) between adjacent mlens
     centroidmethod       int           [0,1]            0                               Centroid method: 0 means barycentric (fast), 1 means gaussian fit (slow)
          medfilter       int           [0,1]            1                        1: Median filtering of dispersion coeff and tilts with a (5x5) median filtering
               Save       int           [0,1]            1                                                                  1: save output on disk, 0: don't save
            iscalib       int           [0,1]            1                                  1: save to Calibrations Database, 0: save in regular reduced data dir
      lamp_override       int           [0,1]            0                                                            0,1: override the filter/lamp combinations?
   gpitvim_dispgrid       int         [0,500]           15    1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display 
              gpitv       int         [0,500]            0                                 1-500: choose gpitv session for displaying wavcal file, 0: no display 
              tests       int           [0,3]            0                                                                                 1 for extensive tests 
           testsDST       int           [0,3]            0                                                                                       1 for DST tests 
===================  ========  ==============  ===========  =====================================================================================================


**IDL Filename**: gpi_extract_wavcal2.pro


.. index::
    single:Measure locations of Emission Lines

.. _MeasurelocationsofEmissionLines:

Measure locations of Emission Lines
-----------------------------------

 Derive wavelength calibration from an arc lamp or flat-field image.

**Category**:  Calibration      **Order**: 1.73

**Inputs**:  2D image from narrow band arclamp

**Outputs**: Not specified      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	gpi_extract_wavcal detects positions of spectra in the image with narrow
	band lamp image.


	**NOTE**: This is a slightly different variant algorithm compared to
	gpi_extract_wavcal. Mostly for testing purposes. It is recommended
	that most users stick with the default calibration routine for now.

 ALGORITHM:
	gpi_extract_wavcal starts by detecting the central peak of the image.
	Next, starting with a initial value of w & P, find the nearest peak (with an increment on the microlens coordinates)
	when nearest peak has been detected, it reevaluates w & P and so forth..


 common needed:


 HISTORY:
 	 Jerome Maire 2008-10
	  JM: nlens, w (initial guess), P (initial guess), cenx (or centrXpos), ceny (or centrYpos) as parameters
   2009-09-17 JM: added DRF parameters
   2009-12-10 JM: initiate position at 1.5microns so we can take into account several
   2010-07-14 J.Maire:for DRP testing, correct for DST finite spectral resolution

**Parameters**:

===================  ========  ==============  =========  =====================================================================================================
               Name      Type           Range    Default                                                                                            Description
===================  ========  ==============  =========  =====================================================================================================
              nlens       int         [0,400]        281                                                                    side length of  the  lenslet array 
          centrXpos       int        [0,2048]       1024                                   Initial approximate x-position [pixel] of central peak at 1.5microns
          centrYpos       int        [0,2048]       1024                                   Initial approximate y-position [pixel] of central peak at 1.5microns
                  w     float        [0.,10.]        4.8                         Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel
                  P     float        [-7.,7.]       -1.8                                                                                    Micro-pupil pattern
  wav_of_centrXYpos       int           [1,2]          2     1 if centrX-Ypos is the smallest-wavelength peak of the band; 2 if centrX-Ypos refer to 1.5microns
             maxpos     float        [-7.,7.]         2.                                 Allowed maximum location fluctuation (in pixel) between adjacent mlens
            maxtilt     float    [-360.,360.]        10.                                    Allowed maximum tilt fluctuation (in degree) between adjacent mlens
          medfilter       int           [0,1]          1                        1: Median filtering of dispersion coeff and tilts with a (5x5) median filtering
               Save       int           [0,1]          1                                                                  1: save output on disk, 0: don't save
             suffix    string            None    -wavcal                                                                                    Enter output suffix
   gpitvim_dispgrid       int         [0,500]         15    1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display 
              gpitv       int         [0,500]          0                                 1-500: choose gpitv session for displaying wavcal file, 0: no display 
              tests       int           [0,3]          0                                                                                 1 for extensive tests 
===================  ========  ==============  =========  =====================================================================================================


**IDL Filename**: gpi_extract_wavcal_locations.pro


.. index::
    single:Measure Polarization Spot Calibration

.. _MeasurePolarizationSpotCalibration:

Measure Polarization Spot Calibration
-------------------------------------

 Derive polarization calibration files from a flat field image.

**Category**:  Calibration      **Order**: 1.8

**Inputs**:  2D image from flat field  in polarization mode

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


    gpi_extract_polcal detects the positions of the polarized spots in a 2D
    image based on flat field observations.

 ALGORITHM:
    gpi_extract_polcal starts by detecting the central peak of the image.
    Next, starting with a initial value of w & P, it finds the nearest peak (with an increment on the microlens coordinates)
    when nearest peak has been detected, it reevaluates w & P and so forth..

	Like the spectral mode wavelength calibration code, the first part of this
	algorithm is devoted to determining the positions of each spot on the
	detector.

	Unlike the spectral mode calibration, what we store here is in fact a
	weighted list of pixels for each lenslet PSF. FIXME - this will need some
	revision to accomodate flexure...



 KEYWORDS:
 GEM/GPI KEYWORDS:DISPERSR,FILTER,IFSFILT,FILTER2,OBSTYPE
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
     2009-06-17: Started, based on gpi_extract_wavcal - Marshall Perrin
   2009-09-17 JM: added DRF parameters
   2013-01-28 MMB: added some keywords to pass to find_pol_positions_quadrant

**Parameters**:

===========  =======  ============  =========  ================================================================================
       Name     Type         Range    Default                                                                       Description
===========  =======  ============  =========  ================================================================================
      nlens      int       [0,400]        281                                               side length of  the  lenslet array 
  centrXpos      int      [0,2048]       1024              Initial approximate x-position [pixel] of central peak at 1.5microns
  centrYpos      int      [0,2048]       1024              Initial approximate y-position [pixel] of central peak at 1.5microns
          w    float      [0.,10.]        4.4    Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel
          P    float      [-7.,7.]       2.18                                                               Micro-pupil pattern
     maxpos    float      [-7.,7.]        2.5            Allowed maximum location fluctuation (in pixel) between adjacent mlens
   FitWidth    float    [-10.,10.]          3                                     Size of box around a spot used to find center
       Save      int         [0,1]          1                                                                              None
    Display      int         [0,1]          1                                                                              None
===========  =======  ============  =========  ================================================================================


**IDL Filename**: gpi_extract_polcal.pro


.. index::
    single:Measure Polarization Spot Calibration (parallelized)

.. _MeasurePolarizationSpotCalibration(parallelized):

Measure Polarization Spot Calibration (parallelized)
----------------------------------------------------

 Derive polarization calibration files from a flat field image.

**Category**:  Calibration      **Order**: 1.8

**Inputs**:  2D image from flat field  in polarization mode

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


    gpi_extract_polcal detects the positions of the polarized spots in a 2D
    image based on flat field observations.

 ALGORITHM:
    gpi_extract_polcal starts by detecting the central peak of the image.
    Next, starting with a initial value of w & P, it finds the nearest peak (with an increment on the microlens coordinates)
    when nearest peak has been detected, it reevaluates w & P and so forth..

    ; TODO modify to deal with the 2nd polarization...



 KEYWORDS:
 GEM/GPI KEYWORDS:DISPERSR,FILTER,IFSFILT,FILTER2,OBSTYPE
 DRP KEYWORDS: FILETYPE,ISCALIB



 HISTORY:
     2009-06-17: Started, based on gpi_extract_wavcal - Marshall Perrin
   2009-09-17 JM: added DRF parameters
   2013-01-28 MMB: added some keywords to pass to find_pol_positions_quadrant

**Parameters**:

===========  =======  ============  =========  ================================================================================
       Name     Type         Range    Default                                                                       Description
===========  =======  ============  =========  ================================================================================
      nlens      int       [0,400]        281                                               side length of  the  lenslet array 
  centrXpos      int      [0,2048]       1024              Initial approximate x-position [pixel] of central peak at 1.5microns
  centrYpos      int      [0,2048]       1024              Initial approximate y-position [pixel] of central peak at 1.5microns
          w    float      [0.,10.]        4.8    Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel
          P    float      [-7.,7.]       -1.8                                                               Micro-pupil pattern
     maxpos    float      [-7.,7.]        2.5            Allowed maximum location fluctuation (in pixel) between adjacent mlens
   FitWidth    float    [-10.,10.]          3                                     Size of box around a spot used to find center
       Save      int         [0,1]          1                                                                              None
    Display      int         [0,1]          1                                                                              None
===========  =======  ============  =========  ================================================================================


**IDL Filename**: gpi_extract_polcal_parallelize.pro


.. index::
    single:Shift 2D Image

.. _Shift2DImage:

Shift 2D Image
--------------

 Shift 2D image, by integer or fractional pixel amounts.  Doesn't shift ref pixels. 

**Category**:  ALL      **Order**: 1.9

**Inputs**:  Any 2D image

**Outputs**:  2D image shifted by (dx, dy).      **Output Suffix**:  'shifted'

**Notes**:

.. code-block:: idl


  Shift a 2D image in X and Y by arbitrary amounts.

  This routine was developed for pipeline testing to mock up flexure
  and is not intended for regular use in data reduction. Use at your
  own risk!

  Only the actual science pixels are shifted; reference pixels are NOT
  shifted. The best way to use this is thus after reference pixel
  subtraction but before datacube extraction


 	2D image corrected

 ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.


 HISTORY:
   2012-12-18 MP: New primitive.
   2013-01-16 MP: Documentation cleanup

**Parameters**:

=======  =======  ==========  =========  ===================================================================
   Name     Type       Range    Default                                                          Description
=======  =======  ==========  =========  ===================================================================
     dx    float    [-10,10]          0                                          shift amount in X direction
     dy    float    [-10,10]          0                                          shift amount in Y direction
   Save      int       [0,1]          0                                1: save output on disk, 0: don't save
  gpitv      int     [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=======  =======  ==========  =========  ===================================================================


**IDL Filename**: shift_2d_image.pro


.. index::
    single:Update Spot Shifts for Flexure

.. _UpdateSpotShiftsforFlexure:

Update Spot Shifts for Flexure
------------------------------

 Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis

**Category**:  SpectralScience, Calibration, PolarimetricScience      **Order**: 1.99

**Inputs**: Not specified

**Outputs**: Not specified      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


  This primitive updates the wavelength calibration and spot location table
  to account for shifts in the apparent position of each spectrum due to
  elevation-dependent flexure within the IFS.  The observed image motion is
  about 0.7 pixels in X and 0.5 pixels in Y between 0 and 90 degrees

  By updating the X and Y coordinates of each lenslet across the field of view,
  this primitive enables the extraction of well behaved data cubes
  regardless of the orientation.

  There are several options for how to determine the shifts, set by the
  method keyword:

    method="None"     No correction applied.
    method='Manual'   Apply shifts provided by the user via the
                      manual_dx and manual_dy arguments.
    method='Lookup'   Correction applied based on a lookup table of shifts
                      precomputed based on arc lamp data at multiple
                      orientations, obtained from the calibration database.
    method='Auto'     [work in progress, use at your own risk]
                      Attempt to determine the shifts on-the-fly from each
                      individual exposure via model fitting.

 If the 'gpitv' argument to this primitive is used to send the output
 image to a gpitv session, it will be displayed *with the updated
 wavelength calibration information overplotted*.



 HISTORY:
   2013-03-08 MP: Started based on extractcube, initial attempts at automated
                   on-the-fly measurements.
   2013-03-25 JM: Implemented lookup table version.
   2013-04-22 PI: A few bug fixes to lookup table code.
   2013-04-25 MP: Documentation improvements.
   2013-06-04 JBR: Now compatible with polarimetry.

**Parameters**:

===========  ========  ===========================  =========  ========================================================================
       Name      Type                        Range    Default                                                               Description
===========  ========  ===========================  =========  ========================================================================
     method    string    [None|Manual|Lookup|Auto]       None      How to correct spot shifts due to flexure? [None|Manual|Lookup|Auto]
  manual_dx     float                     [-10,10]          0    If method=Manual, the X shift of spectra at the center of the detector
  manual_dy     float                     [-10,10]          0    If method=Manual, the Y shift of spectra at the center of the detector
    display    string                     [yes|no]         no                               Show diagnostic plot when running? [yes|no]
       Save       int                        [0,1]          0                                     1: save output on disk, 0: don't save
      gpitv       int                      [0,500]          0         1-500: choose gpitv session for displaying output, 0: no display 
===========  ========  ===========================  =========  ========================================================================


**IDL Filename**: update_shifts_for_flexure.pro


.. index::
    single:Assemble Datacube

.. _AssembleDatacube:

Assemble Datacube
-----------------

 Extract a 3D datacube from a 2D image (Calls assemble spectral or polarimetric cube automatically depending on input data format)

**Category**:  ALL      **Order**: 2.0

**Inputs**:  detector image

**Outputs**: 

**Notes**:

.. code-block:: idl


		This is a wrapper routine to call either the spectral, polarized, or
		undispersed extraction routines, depending on whichever is appropriate
		for the current file.

		This routine transforms a 2D detector image in the dataset.currframe input
		structure into a 2 or 3D data cube in the dataset.currframe output structure.

 common needed: filter, wavcal, tilt, (nlens)

 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER2
 DRP KEYWORDS:


 HISTORY:
   2009-04-22 MDP: Created
   2009-09-17 JM: added DRF parameters

**Parameters**:

======  ======  =======  =========  =============
  Name    Type    Range    Default    Description
======  ======  =======  =========  =============
  Save     int    [0,1]          0           None
======  ======  =======  =========  =============


**IDL Filename**: extract.pro


.. index::
    single:Assemble Spectral Datacube using mlens PSF

.. _AssembleSpectralDatacubeusingmlensPSF:

Assemble Spectral Datacube using mlens PSF
------------------------------------------

 Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis

**Category**:       **Order**: 2.0

**Inputs**: Not specified

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


		This routine transforms a 2D detector image in the dataset.currframe input
		structure into a 3D data cube in the dataset.currframe output structure.
   This routine extracts data cube from an image using an inversion method along the dispersion axis



 KEYWORDS:
 GEM/GPI KEYWORDS:


 HISTORY:
 	Originally by Jerome Maire 2007-11
   2012-02-01 JM: adapted to vertical dispersion
   2012-02-15 JM: adapted as a pipeline module

**Parameters**:

=================  ==========  =========  ===========  ===================================================================
             Name        Type      Range      Default                                                          Description
=================  ==========  =========  ===========  ===================================================================
             Save         int      [0,1]            1                                1: save output on disk, 0: don't save
  CalibrationFile    mlenspsf       None    AUTOMATIC                Filename of the mlens-PSF calibration file to be read
           suffix      string       None       -spdci                                                  Enter output suffix
      ReuseOutput         int      [0,1]            0               1: keep output for following primitives, 0: don't keep
            gpitv         int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ==========  =========  ===========  ===================================================================


**IDL Filename**: gpi_extractcube_mlenspsf.pro


.. index::
    single:Assemble Spectral Datacube

.. _AssembleSpectralDatacube:

Assemble Spectral Datacube
--------------------------

 Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis

**Category**:  SpectralScience, Calibration      **Order**: 2.0

**Inputs**: Not specified

**Outputs**:       **Output Suffix**: '-rawspdc'

**Notes**:

.. code-block:: idl


        This routine transforms a 2D detector image in the dataset.currframe input
        structure into a 3D data cube in the dataset.currframe output structure.
   This routine extracts data cube from an image using spatial summation along the dispersion axis
     introduced suffix '-rawspdc' (raw spectral data-cube)

 KEYWORDS:
 GEM/GPI KEYWORDS:IFSFILT


 HISTORY:
     Originally by Jerome Maire 2007-11
   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
   2008-06-06 JM: adapted to pipeline inputs
   2009-04-15 MDP: Documentation updated.
   2009-06-20 JM: adapted to wavcal input
   2009-09-17 JM: added DRF parameters
   2012-02-01 JM: adapted to vertical dispersion
   2012-02-09 DS: offloaded sdpx calculation
   2013-04-02 JBR: Correction on the y coordinate when reading the det array to match centered pixel convention.
                   Removal of the reference pixel area.
   2013-04-27 MDP: Documentation update, code cleanup to relabel X and Y properly

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          0                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: extractcube.pro


.. index::
    single:Assemble Undispersed Image

.. _AssembleUndispersedImage:

Assemble Undispersed Image
--------------------------

 Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis

**Category**:  Calibration      **Order**: 2.0

**Inputs**: Not specified

**Outputs**: 

**Notes**:

.. code-block:: idl


	This routine performs a simple extraction of GPI IFS undispersed
	data. It requires a pair of fits files explicitly named xlocs.fits
	and ylocs.fits located in the current directory. Those files contain
	a 300x300 array of x and y positions for spots. These files are
	produced by the routine identify.pro which examines a flood illuminated
	grid of spots.

	The routine currently assumes the spots in the IFS are shifted by
	2.36 and 2.63 pixels from the time the calibration frame was taken
	in the UCLA lab. If your image has significant flux in the central lenslets
	then you can comment out the fitting portion of the code, and the
	pattern shift will be determined for you.

	fname = name of the fits file you want to reduce
	outname = name of the output file this routine will produce

	example usage:
	     extu, "test0159.fits", "extu0159.fits"


 KEYWORDS:


 HISTORY:
   Originally by James Larkin as extu.pro
   2012-02-07 Pipelinified by Marshall Perrin
   2012-03-30 Rotated by 90 deg to match spectral cube orientation. NaNs outside of FOV. - MP
   2013-03-08 JM: added manual shifts of the spot due to flexure

**Parameters**:

=========  ========  ============  =========  ===================================================================
     Name      Type         Range    Default                                                          Description
=========  ========  ============  =========  ===================================================================
   xshift     float    [-100,100]     -2.363                                                 Shift in X direction
   yshift     float    [-100,100]    -2.6134                                                 Shift in Y direction
  boxsize     float        [0,10]          5                           Size of box to use for spectral extraction
     Save       int         [0,1]          0                                1: save output on disk, 0: don't save
   suffix    string          None      -extu                                                  Enter output suffix
    gpitv       int       [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=========  ========  ============  =========  ===================================================================


**IDL Filename**: extractcube_undispersed.pro


.. index::
    single:Assemble Spectral Datacube (bp)

.. _AssembleSpectralDatacube(bp):

Assemble Spectral Datacube (bp)
-------------------------------

 Extract a 3D datacube from a 2D image taking account of the hot/cold pixel map (need to use also readbadpixmap with this primitive).

**Category**:  SpectralScience      **Order**: 2.0

**Inputs**: Not specified

**Outputs**: 

**Notes**:

.. code-block:: idl


         extract data cube from an image using spatial summation along the dispersion axis
          introduced suffix '-spdc' (spectral data-cube)

        This routine transforms a 2D detector image in the dataset.currframe input
        structure into a 3D data cube in the dataset.currframe output structure.


 KEYWORDS:
 GEM/GPI KEYWORDS:IFSFILT


 HISTORY:
     Originally by Jerome Maire 2007-11
   2008-04-02 JM: spatial summation window centered on pixel and interpolation on the zem. comm. wav. vector
      2008-06-06 JM: adapted to pipeline inputs
   2009-04-15 MDP: Documentation updated.
   2009-06-20 JM: adapted to wavcal input
   2009-08-30 JM: take into acount bad-pixels
   2009-09-17 JM: added DRF parameters
   2012-10-18 MP: Code cleanup and debugging.

**Parameters**:

========  ========  =========  ==========  ===================================================================
    Name      Type      Range     Default                                                          Description
========  ========  =========  ==========  ===================================================================
    Save       int      [0,1]           0                                1: save output on disk, 0: don't save
  suffix    string       None    -rawspdc                                                  Enter output suffix
   gpitv       int    [0,500]           0    1-500: choose gpitv session for displaying output, 0: no display 
========  ========  =========  ==========  ===================================================================


**IDL Filename**: extractcube_withbadpix.pro


.. index::
    single:Assemble Polarization Cube

.. _AssemblePolarizationCube:

Assemble Polarization Cube
--------------------------

 Extract 2 perpendicular polarizations from a 2D image.

**Category**:  PolarimetricScience, Calibration      **Order**: 2.0

**Inputs**:  detector image

**Outputs**:       **Output Suffix**: '-podc'

**Notes**:

.. code-block:: idl


         extract polarization-mode data cube from an image
        define first suffix '-podc' (polarization data-cube)

        This routine transforms a 2D detector image in the dataset.currframe input
        structure into a 3D data cube in the dataset.currframe output structure.
        (not much of a data cube - really just 2x 2D images)


 ALGORITHM NOTES:

    Ideally this should be done as an optimum weighting
    (see e.g. Naylor et al, 1997 MNRAS)

    That algorithm is as follows: For each lenslet spot,
       -divide each pixel by the expected fraction of the total lenslet flux
        in that pixel. (this makes each pixel an estimate of the total lenslet
        flux)
        -Combine these into a weighted average, weighted by the S/N per pixel


 common needed: filter, wavcal, tilt, (nlens)

 GEM/GPI KEYWORDS:DEC,DISPERSR,PRISM,FILTER,FILTER2,PAR_ANG,RA,WPANGLE
 DRP KEYWORDS:CDELT1,CDELT2,CDELT3,CRPIX1,CRPIX2,CRPIX3,CRVAL1,CRVAL2,CRVAL3,CTYPE1,CTYPE2,CTYPE3,CUNIT1,CUNIT2,CUNIT3,EQUINOX,FILETYPE,HISTORY, PC1_1,PC1_2,PC2_1,PC2_2,PC3_3,RADESYS,WCSAXES


 HISTORY:
   2009-04-22 MDP: Created, based on DST's cubeextract_polarized.
   2009-09-17 JM: added DRF parameters
   2009-10-08 JM: add gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-15 MP: Code cleanup.
   2011-06-07 JM: added FITS/MEF compatibility
   2013-01-02 MP: Updated output file orientation to be consistent with
				   spectral mode and raw data.

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          0                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: extractpol.pro


.. index::
    single:Noise and Flux Analysis

.. _NoiseandFluxAnalysis:

Noise and Flux Analysis
-----------------------

 Store a few key values as fits keywords in the file. It can generate anciliary files too.

**Category**:  SpectralScience, Calibration, PolarimetricScience      **Order**: 2.1

**Inputs**: Not specified

**Outputs**:  Changes is the header of the file without changing the data and saving a fits file report with the value of the sliding median/standard deviation computation.      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


   This routine quantifies the noise and the flux in an image without changing it. It generates fits keyword for this values for further easy image sorting.
   If asked, it can generate a fits files too.

   If Flux = 1: Generate fits keywords related with total flux in the image
     DN, total data number of the image.
     DNLENS, total data number in the lenslets aera (if not a dark and not a cube)
     DNBACK, total data number outside the lenslets aera (if not a dark and not a cube)


   If StddevMed > 1: Generate fits keywords related with the standard deviation in the image

   If StddevMed = 2:
     Compute the local median and the local standard deviation by moving a square of size Width.
     Because it is time consuming, you can skip pixels using the parameter PixelsSkipped.
     In the output, the finite value pixels correspond to pixels where the media and the standard deviation were computed.
     If 2d image: Generate a file with the suffix '-stddevmed' containing an 3d array. [*,*,0] is the median and [*,*,1] is the standard deviation.
     If 3d image: Generate two files '-stddev' and '-median'. Both same size of the original image.


   If microNoise = 1:
     Estimate the quantity of microphonics noise in the image based on a model stored as a calibration file.
     The quantity of microphonics noise is measured with the ratio of the dot_product and the norm of the image: dot_product/sqrt(sum(abs(fft(image))^2)).
     With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.
     The fits keyword associated is MICRONOI.


   If FourierTransf = 1 or 2:
     Build and save the Fourier transform of the image.
     If 1, the output is the one directly from the idl function (fft). Therefore, the Fourier image is not centered.
     If 2, the output will be centered.
     In the case of a cube it is not a 3d fft that is performed but several 2d ffts.
     suffix='-absfft' or suffix='-absfftdc' if it is a cube.

 KEYWORDS:



 HISTORY:
   Originally by Jean-Baptiste Ruffio 2013-05

**Parameters**:

=================  ========  ==========  ===========  ===============================================================================================================================================================================================================
             Name      Type       Range      Default                                                                                                                                                                                                      Description
=================  ========  ==========  ===========  ===============================================================================================================================================================================================================
             Flux       int       [0,1]            1                                                                                                                                                                                            Trigger flux analysis
        StddevMed       int       [0,2]            1    Trigger the standard deviation (and median) analysis of the image. if StddevMed=1, only keywords and log are produced. If StddevMed=2, fits files are generated with a sliding median and standard deviation.
            Width       int    [3,2048]          101                                                                                                                                                  If Stddev = 2, Width of the moving rectangle. It has to be odd.
    PixelsSkipped       int    [0,2047]          100                                                                                                                                                                 If Stddev = 2, Pixels skipped between two points
       MicroNoise       int       [0,1]            1                                                                                                                                                                          Trigger the microphonics noise analysis
  CalibrationFile    string        None    AUTOMATIC                                                                                                                                                       Filename of the desired microphonics model file to be read
    FourierTransf       int     [0,1,2]            1                                                                                                                               1: frequency 0 on the bottom left. 2: frequencies 0 will be centered on the image.
             Save       int       [0,1]            0                                                                                                                                                                            1: save output on disk, 0: don't save
            gpitv       int     [0,500]            0                                                                                                                                                1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  ==========  ===========  ===============================================================================================================================================================================================================


**IDL Filename**: noise_flux_analysis.pro


.. index::
    single:Divide by Spectral Flat Field

.. _DividebySpectralFlatField:

Divide by Spectral Flat Field
-----------------------------

 Divides a spectral data-cube by a flat field data-cube.

**Category**:  SpectralScience,Calibration      **Order**: 2.2

**Inputs**:  data-cube

**Outputs**:   datacube with slice at the same wavelength

**Notes**:

.. code-block:: idl



 KEYWORDS:
    /Save    set to 1 to save the output image to a disk file.

 DRP KEYWORDS: HISTORY


 HISTORY:
     2009-08-27: JM created
   2009-09-17 JM: added DRF parameters
   2009-10-09 JM added gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07 JM: added check for NAN & zero
   2012-10-11 MP: Added min/max wavelength checks
   2012-10-17 MP: Removed deprecated suffix= keyword

**Parameters**:

=================  ==========  =========  ===========  ===================================================================
             Name        Type      Range      Default                                                          Description
=================  ==========  =========  ===========  ===================================================================
  CalibrationFile    specflat       None    AUTOMATIC       Filename of the desired wavelength calibration file to be read
             Save         int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv         int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ==========  =========  ===========  ===================================================================


**IDL Filename**: spectral_flat_div.pro


.. index::
    single:Remove Flat Lamp spectrum

.. _RemoveFlatLampspectrum:

Remove Flat Lamp spectrum
-------------------------

 Fit the lamp spectrum and remove it (for delivering flat field cubes)

**Category**:  Calibration      **Order**: 2.25

**Inputs**:  data-cube

**Outputs**:   datacube with slice at the same wavelength      **Output Suffix**: 'specflat'

**Notes**:

.. code-block:: idl

                                 Rescale flat-field (keep large scale variations)




 GEM/GPI KEYWORDS:
 DRP KEYWORDS: FILETYPE, ISCALIB



 HISTORY:
 	2009-06-20 JM: created
 	2009-07-22 MP: added doc header keywords
 	2012-10-11 MP: added min/max wavelength checks

**Parameters**:

========  ========  ===============================  ===========  ===================================================================
    Name      Type                            Range      Default                                                          Description
========  ========  ===============================  ===========  ===================================================================
    Save       int                            [0,1]            1                                1: save output on disk, 0: don't save
   gpitv       int                          [0,500]            2    1-500: choose gpitv session for displaying output, 0: no display 
  method    string    polyfit|linfit|blackbody|none    blackbody                             Method to use for removing lamp spectrum
========  ========  ===============================  ===========  ===================================================================


**IDL Filename**: remove_lamp_spectrum.pro


.. index::
    single:Interpolate Wavelength Axis

.. _InterpolateWavelengthAxis:

Interpolate Wavelength Axis
---------------------------

 Interpolate spectral datacube onto regular wavelength sampling.

**Category**:  SpectralScience,Calibration      **Order**: 2.3

**Inputs**: 

**Outputs**:   datacube with slice at the same wavelength      **Output Suffix**: '-spdc'

**Notes**:

.. code-block:: idl


		interpolate datacube to have each slice at the same wavelength
		add wavelength keywords to the FITS header




 KEYWORDS:
 GEM/GPI KEYWORDS:
 DRP KEYWORDS: CDELT3,CRPIX3,CRVAL3,CTYPE3,CUNIT3
	/Save	Set to 1 to save the output image to a disk file.



 HISTORY:
 	Originally by Jerome Maire 2008-06
 	2009-04-15 MDP: Documentation improved.
   2009-06-20 JM: adapted to wavcal
   2009-09-17 JM: added DRF parameters
   2010-03-15 JM: added error handling
   2012-12-09 MP: Updates to WCS output

**Parameters**:

==================  ======  =========  =========  ===================================================================
              Name    Type      Range    Default                                                          Description
==================  ======  =========  =========  ===================================================================
  Spectralchannels     int    [0,100]         37                Choose how many spectral channels for output datacube
              Save     int      [0,1]          1                                1: save output on disk, 0: don't save
             gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
==================  ======  =========  =========  ===================================================================


**IDL Filename**: interpol_spec_oncommwavvect.pro


.. index::
    single:Measure GPI distortion from grid pattern

.. _MeasureGPIdistortionfromgridpattern:

Measure GPI distortion from grid pattern
----------------------------------------

 Measure GPI distortion from grid pattern

**Category**:  Calibration      **Order**: 2.44

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: '-distor'

**Notes**:

.. code-block:: idl





 KEYWORDS:




 HISTORY:
 	Originally by Jerome Maire 2009-12
       Switched sxaddpar to backbone->set_keyword 01.31.2012 Dmitry Savransky

**Parameters**:

======  ======  =======  =========  =======================================
  Name    Type    Range    Default                              Description
======  ======  =======  =========  =======================================
  Save     int    [0,1]          1    1: save output on disk, 0: don't save
======  ======  =======  =========  =======================================


**IDL Filename**: gpi_measure_distortion.pro


.. index::
    single:Measure satellite spot locations

.. _Measuresatellitespotlocations:

Measure satellite spot locations
--------------------------------

 Calculate locations of satellite spots in datacubes 

**Category**:  Calibration,SpectralScience      **Order**: 2.44

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: '-satspots'

**Notes**:

.. code-block:: idl





 KEYWORDS:

 GEM/GPI KEYWORDS:
 DRP KEYWORDS: FILETYPE,ISCALIB,SPOTWAVE



 HISTORY:
 	Originally by Jerome Maire 2009-12
       09-18-2012 Offloaded functionality to common backend - ds

**Parameters**:

=================  ======  =========  =========  ==================================================================================================================================
             Name    Type      Range    Default                                                                                                                         Description
=================  ======  =========  =========  ==================================================================================================================================
      refine_fits     int      [0,1]          1                                                                                   0: Use wavelength scaling only; 1: Fit each slice
  reference_index     int     [0,50]          0                                                                              Index of slice to use for initial satellite detection.
    search_window     int     [1,50]         20                                                                               Radius of aperture used for locating satellite spots.
             Save     int      [0,1]          0                                                                                               1: save output on disk, 0: don't save
        loc_input     int      [0,2]          0                                                 0: Find spots automatically; 1: Use values below as initial satellite spot location
               x1     int    [0,300]          0        approx x-location of top left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y1     int    [0,300]          0        approx y-location of top left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               x2     int    [0,300]          0     approx x-location of bottom left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y2     int    [0,300]          0     approx y-location of bottom left spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               x3     int    [0,300]          0       approx x-location of top right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y3     int    [0,300]          0       approx y-location of top right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               x4     int    [0,300]          0    approx x-location of bottom right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y4     int    [0,300]          0    approx y-location of bottom right spot on central slice of the datacube in pixels (not considered if CalibrationFile is defined)
=================  ======  =========  =========  ==================================================================================================================================


**IDL Filename**: gpi_meas_sat_spots_locations.pro


.. index::
    single:Measure satellite spot locations with GPItv

.. _MeasuresatellitespotlocationswithGPItv:

Measure satellite spot locations with GPItv
-------------------------------------------

 Calculate locations of sat.spots in datacubes (using GPItv). Do not work with the IDL Virtual Machine.

**Category**:  Calibration      **Order**: 2.44

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: '-spotloc'

**Notes**:

.. code-block:: idl





 KEYWORDS:

 DRP KEYWORDS: DATAFILE,FILETYPE,ISCALIB,SPOTWAVE



 HISTORY:
 	Originally by Jerome Maire 2009-12
       2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky

**Parameters**:

==========  ======  =======  =========  =============================================
      Name    Type    Range    Default                                    Description
==========  ======  =======  =========  =============================================
      Save     int    [0,1]          1          1: save output on disk, 0: don't save
  spotsnbr     int    [1,4]          4    How many spots in a slice of the datacube? 
==========  ======  =======  =========  =============================================


**IDL Filename**: sat_spots_locations.pro


.. index::
    single:Correct GPI distortion

.. _CorrectGPIdistortion:

Correct GPI distortion
----------------------

 Correct GPI distortion

**Category**:  SpectralScience,PolarimetricScience      **Order**: 2.44

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: '-distorcorr'

**Notes**:

.. code-block:: idl





 KEYWORDS:




 HISTORY:
 	Originally by Jerome Maire 2009-12
   2013-04-23 Major change of the code, now based on Quinn's routine for distortion correction - JM

**Parameters**:

=================  ===========  =========  ===========  ===================================================================
             Name         Type      Range      Default                                                          Description
=================  ===========  =========  ===========  ===================================================================
             Save          int      [0,1]            1                                1: save output on disk, 0: don't save
  CalibrationFile    distorcal       None    AUTOMATIC       Filename of the desired distortion calibration file to be read
            gpitv          int    [0,500]           10    1-500: choose gpitv session for displaying output, 0: no display 
=================  ===========  =========  ===========  ===================================================================


**IDL Filename**: gpi_correct_distortion.pro


.. index::
    single:Measure satellite spot peak fluxes

.. _Measuresatellitespotpeakfluxes:

Measure satellite spot peak fluxes
----------------------------------

 Calculate peak fluxes of satellite spots in datacubes 

**Category**:  Calibration,SpectralScience      **Order**: 2.45

**Inputs**:  data-cube, spot locations

**Outputs**:       **Output Suffix**: '-satsfluxes'

**Notes**:

.. code-block:: idl





 KEYWORDS:

 GEM/GPI KEYWORDS:
 DRP KEYWORDS:



 HISTORY:
 	Written 09-18-2012 savransky1@llnl.gov

**Parameters**:

=================  ======  ========  =========  ===================================================================
             Name    Type     Range    Default                                                          Description
=================  ======  ========  =========  ===================================================================
        gauss_fit     int     [0,1]          1    0: Extract maximum pixel; 1: Correlate with Gaussian to find peak
  reference_index     int    [0,50]          0               Index of slice to use for initial satellite detection.
           ap_rad     int    [1,50]          7                           Radius of aperture used for finding peaks.
             Save     int     [0,1]          0                                1: save output on disk, 0: don't save
=================  ======  ========  =========  ===================================================================


**IDL Filename**: gpi_meas_sat_spots_fluxes.pro


.. index::
    single:Load Satellite Spot locations

.. _LoadSatelliteSpotlocations:

Load Satellite Spot locations
-----------------------------

 Load satellite spot locations from calibration file 

**Category**:  SpectralScience      **Order**: 2.45

**Inputs**:  data-cube

**Outputs**: Not specified

**Notes**:

.. code-block:: idl



 DRP KEYWORDS: PSFCENTX,PSFCENTY,SPOT[1-4][x-y],SPOTWAVE


 HISTORY:
 	Originally by Jerome Maire 2009-12
   2010-10-19 JM: split HISTORY keyword if necessary
   2013-07-10 MP: Documentation update, code cleanup.

**Parameters**:

=================  =========  =======  ===========  ========================================================
             Name       Type    Range      Default                                               Description
=================  =========  =======  ===========  ========================================================
  CalibrationFile    spotloc     None    AUTOMATIC    Filename of spot locations calibration file to be read
=================  =========  =======  ===========  ========================================================


**IDL Filename**: get_spots_locations.pro


.. index::
    single:Measure telluric transmission

.. _Measuretellurictransmission:

Measure telluric transmission
-----------------------------

 Extract Telluric transmission from satelitte spots (method 1) or from PSF signal (method 2) using theoretical star spectrum. Correct or save the transmisssion.

**Category**:  SpectralScience      **Order**: 2.5

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl






 KEYWORDS:

 GEM/GPI KEYWORDS:
 DRP KEYWORDS: DATAFILE,FILETYPE,ISCALIB,PSFCENTX,PSFCENTY,SPOTix-y,SPOTWAVE,



 HISTORY:
 	Jerome Maire 2010-03

**Parameters**:

============================  ========  =========  =========  ===================================================================
                        Name      Type      Range    Default                                                          Description
============================  ========  =========  =========  ===================================================================
                      method       int      [1,2]          1                         1: Use satellite flux. 2:Use clean PSF area.
            Correct_datacube       int      [0,1]          1     1: Correct datacube from extracted tell trams., 0: don't correct
     Save_corrected_datacube       int      [0,1]          1                    1: save corrected datacube on disk, 0: don't save
  Save_telluric_transmission       int      [0,1]          1                                1: save output on disk, 0: don't save
                      suffix    string       None    -telcal                                                  Enter output suffix
                       gpitv       int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
============================  ========  =========  =========  ===================================================================


**IDL Filename**: extract_telluric_transmission.pro


.. index::
    single:Divide spectral data by telluric transmission

.. _Dividespectraldatabytellurictransmission:

Divide spectral data by telluric transmission
---------------------------------------------

 Divides a spectral data-cube by a flat field data-cube.

**Category**:  SpectralScience,Calibration      **Order**: 2.5

**Inputs**:  data-cube

**Outputs**:   datacube with slice at the same wavelength

**Notes**:

.. code-block:: idl



 KEYWORDS:
	/Save	set to 1 to save the output image to a disk file.

 DRP KEYWORDS: HISTORY


 HISTORY:
 	2009-08-27: JM created
   2009-09-17 JM: added DRF parameters
   2009-10-09 JM added gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-08-01 MP: Update for multi-extension FITS files
   2012-10-10 MP: Minor code cleanup; remove deprecated suffix= parameter

**Parameters**:

=================  ===========  =========  ===========  ===================================================================
             Name         Type      Range      Default                                                          Description
=================  ===========  =========  ===========  ===================================================================
  CalibrationFile    -tellucal       None    AUTOMATIC       Filename of the desired wavelength calibration file to be read
             Save          int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv          int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ===========  =========  ===========  ===================================================================


**IDL Filename**: spectral_telluric_transm_div.pro


.. index::
    single:Extract one spectrum via aperture photometry

.. _Extractonespectrumviaaperturephotometry:

Extract one spectrum via aperture photometry
--------------------------------------------

 Extract one spectrum from a datacube somewhere in the FOV specified by the user.

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**:  data-cube

**Outputs**:  1D spectrum stored as a FITS bintable      **Output Suffix**: '-spectrum'

**Notes**:

.. code-block:: idl


	This primitive performs aperture photometry for a selected location in a datacube cube.
	The result is a FITS table containing the spectrum and its calculated uncertainties.

	The standard IDL Goddard library routine aper.pro is used. The user can set the
	photometry aperture and sky annulus sizes; set either sky radius to 0 to disable
	sky subtraction entirely.

	The radii can be specified in units of lenslets (i.e. datacube spatial pixels)
	in which case the apertures are constant with wavelength, or in units of
	lambda/D, in which case the apertures scale in size with wavelength. Set the
   radius_units keyword to select which.


	The user may either specify a fixed center in (X,Y) coordinates or you can set
	center_method = "AUTO" to have the routine automatically locate the brightest point
	source in the image and measure that.




 HISTORY:

   JM 2010-03 : created module.
   2012-10-17 MP: Removed deprecated suffix keyword. FIXME this needs major cleanup!
   2013-04-25 MP: Major rewrite, almost complete replacement of existing code.

**Parameters**:

===============  ========  ======================  ==========  ===================================================================================================================================================
           Name      Type                   Range     Default                                                                                                                                          Description
===============  ========  ======================  ==========  ===================================================================================================================================================
  center_method    string    [Auto|Manual|Refine]        Auto    How to determine center? Auto=find brightest star in cube, Manual=user provided coords, Refine=start from user coords then look for closest peak.
        xcenter       int                 [0,300]         141                                                                                  X location in datacube for extraction center, if manual center mode
        ycenter       int                 [0,300]         141                                                                                  Y location in datacube for extraction center, if manual center mode
         radius     float                [0,1000]          5.                                                                                          Aperture radius to extract photometry for each wavelength. 
   radius_units    string     [lenslets|lambda/D]    lenslets                                                  Specify aperture+sky radii in units of lenslets (pixels) or lambda/D so they scale with wavelength?
     sky_rad_in     float                [0,1000]         15.                                                                                                                         Inner radius for sky annulus
    sky_rad_out     float                [0,1000]         25.                                                                                                                         Outer radius for sky annulus
        display    string                [yes|no]          no                                                                                                                  Show diagnostic plots when running?
      ps_figure       int                 [0,500]           2                                                                                           1-500: choose # of saved fig suffix name, 0: no ps figure 
           Save       int                   [0,1]           1                                                                                                 1: save output spectrum as FITS table, 0: don't save
===============  ========  ======================  ==========  ===================================================================================================================================================


**IDL Filename**: extract_one_spectrum.pro


.. index::
    single:Calibrate Photometric Flux of extented object

.. _CalibratePhotometricFluxofextentedobject:

Calibrate Photometric Flux of extented object
---------------------------------------------

 Apply photometric calibration of extented object 

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: '-phot'

**Notes**:

.. code-block:: idl





 HISTORY:
 	Originally by Jerome Maire 2009-12
   JM 2010-03 : added sat locations & choice of final units
   JM 2010-08 : routine optimized with simulated test data
   2010-10-19 JM: split HISTORY keyword if necessary
   2010-11-16 JM: save conversion factor in Calibration DataBase for eventual future use (with extended object)

**Parameters**:

=================  ==========  =========  ===========  ==========================================================================================
             Name        Type      Range      Default                                                                                 Description
=================  ==========  =========  ===========  ==========================================================================================
       FinalUnits         int     [0,10]            1    0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz
  CalibrationFile    Fluxconv       None    AUTOMATIC                                    Filename of the desired flux calibration file to be read
             Save         int      [0,1]            1                                                       1: save output on disk, 0: don't save
            gpitv         int    [0,500]            2                           1-500: choose gpitv session for displaying output, 0: no display 
=================  ==========  =========  ===========  ==========================================================================================


**IDL Filename**: apply_photometric_cal_extented.pro


.. index::
    single:Calibrate Photometric Flux and save convertion in DB

.. _CalibratePhotometricFluxandsaveconvertioninDB:

Calibrate Photometric Flux and save convertion in DB
----------------------------------------------------

 Apply photometric calibration using satellite flux 

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl




 GEM/GPI KEYWORDS:EXPTIME,FILTER,IFSFILT,HMAG,IFSUNITS,SECDIAM,SPECTYPE,TELDIAM
 DRP KEYWORDS: CUNIT,FILETYPE,FSCALE,HISTORY,ISCALIB,PSFCENTX,PSFCENTY,SPOT1x,SPOT1y,SPOT2x,SPOT2y,SPOT3x,SPOT3y,SPOT4x,SPOT4y,SPOTWAVE



 HISTORY:
 	Originally by Jerome Maire 2009-12
   JM 2010-03 : added sat locations & choice of final units
   JM 2010-08 : routine optimized with simulated test data
   2010-10-19 JM: split HISTORY keyword if necessary
   2010-11-16 JM: save conversion factor in Calibration DataBase for eventual future use (with extended object)

**Parameters**:

======================  =========  =========  ===========  ==========================================================================================
                  Name       Type      Range      Default                                                                                 Description
======================  =========  =========  ===========  ==========================================================================================
            FinalUnits        int     [0,10]            1    0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz
       CalibrationFile    fluxcal       None    AUTOMATIC                                    Filename of the desired flux calibration file to be read
                  Save        int      [0,1]            1                                                       1: save output on disk, 0: don't save
  Save_flux_convertion        int      [0,1]            1                                       1: save flux convertion factor on disk, 0: don't save
                 gpitv        int    [0,500]            2                           1-500: choose gpitv session for displaying output, 0: no display 
======================  =========  =========  ===========  ==========================================================================================


**IDL Filename**: apply_photometric_cal_02.pro


.. index::
    single:Extract one spectrum, plots

.. _Extractonespectrum,plots:

Extract one spectrum, plots
---------------------------

 Extract one spectrum from a datacube somewhere in the FOV specified by the user.

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl







 KEYWORDS:
	/Save	Set to 1 to save the output image to a disk file.
 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER,IFSUNIT
 DRP KEYWORDS: CUNIT,DATAFILE,SPECCENX,SPECCENY



 HISTORY:

   JM 2010-03 : created module.

**Parameters**:

===========  ========  =====================  =========  ===================================================================================
       Name      Type                  Range    Default                                                                          Description
===========  ========  =====================  =========  ===================================================================================
    xcenter       int               [0,1000]        141                       x-locations in pixel on datacube where extraction will be made
    ycenter       int               [0,1000]        141                       y-locations in pixel on datacube where extraction will be made
     radius     float               [0,1000]         5.    Aperture radius (in pixel i.e. mlens) to extract photometry for each wavelength. 
     method    string    [median|mean|total]      total                                    method of photometry extraction:median,mean,total
  ps_figure       int                [0,500]          2                           1-500: choose # of saved fig suffix name, 0: no ps figure 
       Save       int                  [0,1]          1                                         1: save output (fits) on disk, 0: don't save
     suffix    string                   None      -spec                                                           Enter output suffix (fits)
===========  ========  =====================  =========  ===================================================================================


**IDL Filename**: extract_one_spectrum2.pro


.. index::
    single:Calibrate Photometric Flux

.. _CalibratePhotometricFlux:

Calibrate Photometric Flux
--------------------------

 Apply photometric calibration using satellite flux 

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl



 GEM/GPI KEYWORDS:EXPTIME,FILTER,IFSFILT,HMAG,IFSUNITS,SECDIAM,SPECTYPE,TELDIAM
 DRP KEYWORDS: CUNIT,FILETYPE,FSCALE,HISTORY,ISCALIB,PSFCENTX,PSFCENTY,SPOT1x,SPOT1y,SPOT2x,SPOT2y,SPOT3x,SPOT3y,SPOT4x,SPOT4y,SPOTWAVE


 HISTORY:
 	Originally by Jerome Maire 2009-12
   JM 2010-03 : added sat locations & choice of final units
   JM 2010-08 : routine optimized with simulated test data
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

=================  =========  =========  ===========  ==========================================================================================
             Name       Type      Range      Default                                                                                 Description
=================  =========  =========  ===========  ==========================================================================================
       FinalUnits        int     [0,10]            1    0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz
  CalibrationFile    fluxcal       None    AUTOMATIC                                    Filename of the desired flux calibration file to be read
             Save        int      [0,1]            1                                                       1: save output on disk, 0: don't save
            gpitv        int    [0,500]            2                           1-500: choose gpitv session for displaying output, 0: no display 
=================  =========  =========  ===========  ==========================================================================================


**IDL Filename**: apply_photometric_cal.pro


.. index::
    single:Extract telluric transmission from sat. spots

.. _Extracttellurictransmissionfromsat.spots:

Extract telluric transmission from sat. spots
---------------------------------------------

 Extract Telluric Spectrum from satelitte spots

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl






 KEYWORDS:




 HISTORY:
 	Jerome Maire 2009-12

**Parameters**:

============================  ========  ==========  =========  ===================================================================
                        Name      Type       Range    Default                                                          Description
============================  ========  ==========  =========  ===================================================================
            Correct_datacube       int       [0,1]          1     1: Correct datacube from extracted tell trams., 0: don't correct
     Save_corrected_datacube       int       [0,1]          1                    1: save corrected datacube on disk, 0: don't save
  Save_telluric_transmission       int       [0,1]          1                                1: save output on disk, 0: don't save
                      suffix    string        None    -telcal                                                  Enter output suffix
                       gpitv       int     [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
                      Xspot1       int    [0,2048]         97                Initial approximate x-position [pixel] of sat. spot 1
                      Yspot1       int    [0,2048]        117                Initial approximate y-position [pixel] of sat. spot 1
                      Xspot2       int    [0,2048]        179                Initial approximate x-position [pixel] of sat. spot 2
                      Yspot2       int    [0,2048]        159                Initial approximate y-position [pixel] of sat. spot 2
============================  ========  ==========  =========  ===================================================================


**IDL Filename**: extract_telluric_transmission_meth1.pro


.. index::
    single:Calibrate Photometric Flux - Polarimetry

.. _CalibratePhotometricFlux-Polarimetry:

Calibrate Photometric Flux - Polarimetry
----------------------------------------

 Apply photometric calibration using satellite flux for polarimetry-mode data

**Category**:  PolarimetricScience      **Order**: 2.51

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: '-phot'

**Notes**:

.. code-block:: idl





 HISTORY:
 	Originally by Jerome Maire 2009-12
   JM 2010-03 : added sat locations & choice of final units
   JM 2010-08 : routine optimized with simulated test data
   2010-10-19 JM: split HISTORY keyword if necessary

**Parameters**:

=================  =========  =========  ===========  ==========================================================================================
             Name       Type      Range      Default                                                                                 Description
=================  =========  =========  ===========  ==========================================================================================
       FinalUnits        int     [0,10]            1    0:Counts, 1:Counts/s, 2:ph/s/nm/m^2, 3:Jy, 4:W/m^2/um, 5:ergs/s/cm^2/A, 6:ergs/s/cm^2/Hz
  CalibrationFile    fluxcal       None    AUTOMATIC                                    Filename of the desired flux calibration file to be read
             Save        int      [0,1]            1                                                       1: save output on disk, 0: don't save
            gpitv        int    [0,500]            2                           1-500: choose gpitv session for displaying output, 0: no display 
=================  =========  =========  ===========  ==========================================================================================


**IDL Filename**: apply_photometric_cal_polar.pro


.. index::
    single:Measure satellite spot flux ratios from unocculted image

.. _Measuresatellitespotfluxratiosfromunoccultedimage:

Measure satellite spot flux ratios from unocculted image
--------------------------------------------------------

 Calculate flux ratio between satellite spots and unocculted star image in a given aperture.

**Category**:  Calibration      **Order**: 2.515

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl





 KEYWORDS:

 DRP KEYWORDS: FILETYPE,ISCALIB,PSFCENTX,PSFCENTY,SPOT[1-4][x-y],SPOTWAVE



 HISTORY:
 	Originally by Jerome Maire 2009-12
   JM 2010-08: routine optimized with simulated test data

**Parameters**:

=======  ======  =======  =========  =======================================
   Name    Type    Range    Default                              Description
=======  ======  =======  =========  =======================================
   Save     int    [0,1]          1    1: save output on disk, 0: don't save
  tests     int    [0,1]          0                    1 only for DRP tests 
=======  ======  =======  =========  =======================================


**IDL Filename**: sat_spots_calib_from_unocc.pro


.. index::
    single:Extract telluric transmission from datacube

.. _Extracttellurictransmissionfromdatacube:

Extract telluric transmission from datacube
-------------------------------------------

 Extract Telluric Spectrum from star spec estimated from datacube

**Category**:  SpectralScience      **Order**: 2.52

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl






 KEYWORDS:




 HISTORY:
 	Jerome Maire 2009-12

**Parameters**:

============================  ========  ==========  =========  ===================================================================
                        Name      Type       Range    Default                                                          Description
============================  ========  ==========  =========  ===================================================================
            Correct_datacube       int       [0,1]          1     1: Correct datacube from extracted tell trams., 0: don't correct
     Save_corrected_datacube       int       [0,1]          1                    1: save corrected datacube on disk, 0: don't save
  Save_telluric_transmission       int       [0,1]          1                                1: save output on disk, 0: don't save
                      suffix    string        None    -telcal                                                  Enter output suffix
                       gpitv       int     [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
                      Xspot1       int    [0,2048]         97                Initial approximate x-position [pixel] of sat. spot 1
                      Yspot1       int    [0,2048]        117                Initial approximate y-position [pixel] of sat. spot 1
                      Xspot2       int    [0,2048]        179                Initial approximate x-position [pixel] of sat. spot 2
                      Yspot2       int    [0,2048]        159                Initial approximate y-position [pixel] of sat. spot 2
============================  ========  ==========  =========  ===================================================================


**IDL Filename**: extract_telluric_transmission_meth2.pro


.. index::
    single:Collapse datacube

.. _Collapsedatacube:

Collapse datacube
-----------------

 Collapse the wavelength dimension of a datacube via mean, median or total. 

**Category**:  ALL      **Order**: 2.6

**Inputs**:  any datacube

**Outputs**:  image containing collapsed datacube      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


  TODO: more advanced collapse methods.


 GEM/GPI KEYWORDS:
 DRP KEYWORDS: CDELT3, CRPIX3,CRVAL3,CTYPE3,NAXIS3


 HISTORY:
  2010-04-23 JM created
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

=============  ======  ==============  =========  ====================================================================
         Name    Type           Range    Default                                                           Description
=============  ======  ==============  =========  ====================================================================
       Method    enum    MEDIAN|TOTAL      TOTAL    How to collapse datacube: total or median (with flux conservation)
         Save     int           [0,1]          1                                 1: save output on disk, 0: don't save
  ReuseOutput     int           [0,1]          1                1: keep output for following primitives, 0: don't keep
        gpitv     int         [0,500]          2     1-500: choose gpitv session for displaying output, 0: no display 
=============  ======  ==============  =========  ====================================================================


**IDL Filename**: collapsedatacube.pro


.. index::
    single:Calibrate astrometry from binary (using separation and PA)

.. _Calibrateastrometryfrombinary(usingseparationandPA):

Calibrate astrometry from binary (using separation and PA)
----------------------------------------------------------

 Calculate astrometry from unocculted binaries using user-specified separation and PA at DATEOBS

**Category**:  Calibration      **Order**: 2.6

**Inputs**:  data-cube

**Outputs**:   plate scale & orientation      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl



 GEM/GPI KEYWORDS:CRPA
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
 	Originally by Jerome Maire 2009-12

**Parameters**:

=======  =======  ===========  =========  ========================================================================
   Name     Type        Range    Default                                                               Description
=======  =======  ===========  =========  ========================================================================
    rho    float      [0.,4.]         1.        Separation [arcsec] at date DATEOBS of observation of the binaries
     pa    float    [0.,360.]        4.8    Position angle [degree] at date DATEOBS of observation of the binaries
   Save      int        [0,1]          1                                     1: save output on disk, 0: don't save
  gpitv      int      [0,500]          2         1-500: choose gpitv session for displaying output, 0: no display 
=======  =======  ===========  =========  ========================================================================


**IDL Filename**: calc_astrometry_binaries.pro


.. index::
    single:Simple SSDI

.. _SimpleSSDI:

Simple SSDI
-----------

 Apply SSDI to create a 2D subtracted image from a cube. Given the user's specified wavelength ranges, extract the 3D datacube slices for each of those wavelength ranges. Collapse these down into 2D images by simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1, then compute  diffImage = I1scaled - k* I2

**Category**:  SpectralScience      **Order**: 2.61

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


 		This recipe rescales and subtracts 2 frames in different user-defined bandwidths. This recipe is used for speckle suppression using the Marois et al (2000) algorithm.

		This routine does NOT update the data structures in memory. You **MUST**
		set the keyword SAVE=1 or else the output is silently discarded.

 	input datacube
 	wavelength solution from common block

 KEYWORDS:
 	L1Min=		Wavelength range 1, minimum wavelength [in microns]
 	L1Max=		Wavelength range 1, maximum wavelength [in microns]
 	L2Min=		Wavelength range 2, minimum wavelength [in microns]
 	L2Max=		Wavelength range 2, maximum wavelength [in microns]
 	k=			Multiplicative coefficient for multiplying the image for
 				Wavelength Range *2*. Default value is k=1.

 	/Save		Set to 1 to save the output file to disk

 DRP KEYWORDS: CDELT3,CRPIX3,CRVAL3,CTYPE3,NAXIS3

 ALGORITHM:
	Given the user's specified wavelength ranges, extract the 3D datacube slices
	for each of those wavelength ranges. Collapse these down into 2D images by
	simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1
	using fftscale so that the PSF scale matches that of Image2 (as computed
	from the average wavelength for each image). Then compute
	   diffImage = I1scaled - k* I2
	Then hopefully output the image somewhere if SAVE=1 is set.



 HISTORY:
 	2007-11 Jerome Maire
	2009-04-15 MDP: Documentation updated; slight code cleanup
    2009-09-17 JM: added DRF parameters

**Parameters**:

=============  =======  ===========  =========  ===========================================================================
         Name     Type        Range    Default                                                                  Description
=============  =======  ===========  =========  ===========================================================================
        L1Min    float    [0.9,2.5]       1.55                          Wavelength range 1, minimum wavelength [in microns]
        L1Max    float    [0.9,2.5]       1.57                          Wavelength range 1, maximum wavelength [in microns]
        L2Min    float    [0.9,2.5]       1.60                          Wavelength range 2, minimum wavelength [in microns]
        L2Max    float    [0.9,2.5]       1.65                          Wavelength range 2, maximum wavelength [in microns]
            k    float       [0,10]        1.0    Scaling factor of Intensity(wav_range2) with diffImage = I1scaled - k* I2
         Save      int        [0,1]          1                                        1: save output on disk, 0: don't save
  ReuseOutput      int        [0,1]          1                       1: keep output for following primitives, 0: don't keep
        gpitv      int      [0,500]          5            1-500: choose gpitv session for displaying output, 0: no display 
=============  =======  ===========  =========  ===========================================================================


**IDL Filename**: simplespectraldiff.pro


.. index::
    single:Speckle alignment

.. _Specklealignment:

Speckle alignment
-----------------

 This recipe rescales datacube PSF slices with respect to a chosen reference PSF slice.

**Category**:  SpectralScience      **Order**: 2.61

**Inputs**: 

**Outputs**:       **Output Suffix**:  suffix+'-specalign'

**Notes**:

.. code-block:: idl


 		This recipe rescales datacube slices with respect to a chosen reference slice.

 	input datacube
 	wavelength solution from common block

 KEYWORDS:


 DRP KEYWORDS: CDELT3,CRPIX3,CRVAL3,CTYPE3,NAXIS3

 ALGORITHM:
	Given the user's specified wavelength ranges, extract the 3D datacube slices
	for each of those wavelength ranges.   Rescale slices with respect to a reference slice
	using fftscale so that the PSF scale matches that of reference (as computed
	from the average wavelength for each image).



 HISTORY:
 	2012-02 JM
       07.30.2012 - offladed backend to speckle_align - ds
       05.10.2012 - updates to match other primitives and to reflect
                    changes to backend by Tyler Barker

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
      k     int    [0,100]          0                                           Slice of the reference PSF
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          5    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_specklealignement.pro


.. index::
    single:Calibrate astrometry from binary (using 6th orbit catalog)

.. _Calibrateastrometryfrombinary(using6thorbitcatalog):

Calibrate astrometry from binary (using 6th orbit catalog)
----------------------------------------------------------

 Calculate astrometry from unocculted binaries; Calculate Separation and PA at date DATEOBS using the sixth orbit catalog.

**Category**:  Calibration      **Order**: 2.61

**Inputs**:  data-cube

**Outputs**:   plate scale & orientation, saved as calibration file      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl





 GEM/GPI KEYWORDS:CRPA,DATE-OBS,OBJECT,TIME-OBS
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
 	Originally by Jerome Maire 2009-12

**Parameters**:

======  ======  =======  =========  =======================================
  Name    Type    Range    Default                              Description
======  ======  =======  =========  =======================================
  Save     int    [0,1]          1    1: save output on disk, 0: don't save
======  ======  =======  =========  =======================================


**IDL Filename**: calc_astrometry_binaries_sixth_orbit_catalog.pro


.. index::
    single:Plot the satellite spot locations vs. the expected location from wavelength scaling

.. _Plotthesatellitespotlocationsvs.theexpectedlocationfromwavelengthscaling:

Plot the satellite spot locations vs. the expected location from wavelength scaling
-----------------------------------------------------------------------------------

 Measured vs. wavelength scaled sat spot locations

**Category**:  SpectralScience,PolarimetricScience      **Order**: 2.7

**Inputs**: 

**Outputs**: 

**Notes**:

.. code-block:: idl



 KEYWORDS:


 	Plot of results.




 HISTORY:
 	written 12/11/2012 - ds

**Parameters**:

==========  ========  ==========  =========  ==================================================
      Name      Type       Range    Default                                         Description
==========  ========  ==========  =========  ==================================================
   Display       int    [-1,100]          0    Window number to display in.  -1 for no display.
  SaveData    string        None                      Save data to filename (blank for no save)
   SavePNG    string        None                Save plot to filename as PNG(blank for no save)
==========  ========  ==========  =========  ==================================================


**IDL Filename**: gpi_meas_satspot_dev.pro


.. index::
    single:Measure the contrast

.. _Measurethecontrast:

Measure the contrast
--------------------

 Measure the contrast. 

**Category**:  SpectralScience,PolarimetricScience      **Order**: 2.7

**Inputs**: 

**Outputs**: 

**Notes**:

.. code-block:: idl




 KEYWORDS:


 	Contrast datacube, plot of contrast curve




 HISTORY:
 	initial version imported GPItv (with definition of contrast corrected) - JM

**Parameters**:

==================  ========  ==========  ============  ==========================================================================================
              Name      Type       Range       Default                                                                                 Description
==================  ========  ==========  ============  ==========================================================================================
              Save       int       [0,1]             0                                                       1: save output on disk, 0: don't save
           Display       int    [-1,100]             0                                            Window number to display in.  -1 for no display.
       SaveProfile    string        None                  Save radial profile to filename as FITS (blank for no save, dir name for default naming)
           SavePNG    string        None                            Save plot to filename as PNG (blank for no save, dir name for default naming) 
        contrsigma     float    [0.,20.]            5.                                                                        Contrast sigma limit
             slice       int     [-1,50]             0                                                                   Slice to plot. -1 for all
      DarkHoleOnly       int       [0,1]             1                           0: Plot profile in dark hole only; 1: Plot outer profile as well.
       contr_yunit       int       [0,2]             0                                                  0: Standard deviation; 1: Median; 2: Mean.
       contr_xunit       int       [0,1]             0                                                                     0: Arcsec; 1: lambda/D.
            yscale       int       [0,1]             0                                                  0: Auto y axis scaling; 1: Manual scaling.
  contr_yaxis_type       int       [0,1]             1                                                                           0: Linear; 1: Log
   contr_yaxis_min     float     [0.,1.]    0.00000001                                                                              Y axis minimum
   contr_yaxis_max     float     [0.,1.]            1.                                                                              Y axis maximum
==================  ========  ==========  ============  ==========================================================================================


**IDL Filename**: measurecontrast.pro


.. index::
    single:KLIP algorithm noise reduction

.. _KLIPalgorithmnoisereduction:

KLIP algorithm noise reduction
------------------------------

 Reduce background noise using the KLIP algorithm

**Category**:  SpectralScience      **Order**: 2.8

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


             This algorithm reduces noise in a datacube using the
             KLIP algorithm

       input datacube
       wavelength solution from common block

 KEYWORDS:

 GEM/GPI KEYWORDS:

 DRP KEYWORDS:

       A reduced datacube with reduced noise

 ALGORITHM:
       Measure annuli out from the center of the cube and create a
       reference set for each annuli of each slice. Apply KLIP to the
       reference set and project the target slice onto the KL
       transform vector. Subtract the projected image from the
       original and repeat for all slices


 HISTORY:
        Written 2013. Tyler Barker

**Parameters**:

==========  =======  ===========  =========  ===================================================================
      Name     Type        Range    Default                                                          Description
==========  =======  ===========  =========  ===================================================================
      Save      int        [0,1]          1                                1: save output on disk, 0: don't save
  refslice      int      [0,100]          0                                           Slice of the reference PSF
    annuli      int      [0,100]         10                                                Number of annuli used
  movement    float    [0.0,5.0]        2.0                             Minimum pixel movement for reference set
      prop    float    [0.8,1.0]     .99999      Proportion of eigenvalues used to truncate KL transform vectors
    arcsec    float    [0.0,1.0]         .4                                Radius of interest if using 1 annulus
    signal      int        [0,1]          0              1: calculate signal to noise ration, 0: don't calculate
     gpitv      int      [0,500]          5    1-500: choose gpitv session for displaying output, 0: no display 
==========  =======  ===========  =========  ===================================================================


**IDL Filename**: klip_alg.pro


.. index::
    single:Update World Coordinates

.. _UpdateWorldCoordinates:

Update World Coordinates
------------------------

 Add wcs info, assuming target star is precisely centered.

**Category**:  ALL      **Order**: 2.9

**Inputs**: 

**Outputs**:       **Output Suffix**: '-addwcs'	; output suffix

**Notes**:

.. code-block:: idl


    Creates a WCS-compliant header based on the target star's RA and DEC.
    Currently assumes the target star is precisely centered.


 KEYWORDS:
     CalibrationFile=    Name of astrometric binaries calibration file


 GEM/GPI KEYWORDS:CRPA,RA,DEC
 DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,CTYPE1,CTYPE2,HISTORY,PC1_1,PC2_2,PSFCENTX,PSFCENTY


 HISTORY:
  JM 2009-12
  JM 2010-03-10: add handle of x0,y0 ref point with PSFcenter
  2010-10-19 JM: split HISTORY keyword if necessary
  2011-08-01 MP: Update for multi-extension FITS

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    astrom       None    AUTOMATIC                                                                 None
             Save       int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: addwcs.pro


.. index::
    single:Normalize polarimetry flats

.. _Normalizepolarimetryflats:

Normalize polarimetry flats
---------------------------

 Normalize a polarimetry-mode flat field to unity.

**Category**:  Calibration      **Order**: 3.1992

**Inputs**:  data-cube

**Outputs**:   datacube with slice at the same wavelength      **Output Suffix**: 'polflat'

**Notes**:

.. code-block:: idl



 KEYWORDS:
	/Save	set to 1 to save the output image to a disk file.

 GEM/GPI KEYWORDS:
 DRP KEYWORDS:NAXES,NAXISi,FILETYPE,ISCALIB


 HISTORY:
 	2009-06-20: JM created
 	2009-07-22: MDP added doc header keywords
   2009-09-17 JM: added DRF parameters
   2009-10-09 JM added gpitv display
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: pol_flat_norm.pro


.. index::
    single:Divide by Polarized Flat Field

.. _DividebyPolarizedFlatField:

Divide by Polarized Flat Field
------------------------------

 Divides a 2-slice polarimetry file by a flat field.

**Category**:  PolarimetricScience, Calibration      **Order**: 3.5

**Inputs**:  data-cube

**Outputs**:   datacube with slice flat-fielded      **Output Suffix**: Modules[thisModuleIndex].suffix

**Notes**:

.. code-block:: idl



 GEM/GPI KEYWORDS:
 DRP KEYWORDS: HISTORY



 HISTORY:
   2009-07-22: MDP created
   2009-09-17 JM: added DRF parameters
   2009-10-09 JM added gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

=================  =========  =========  ===========  ===================================================================
             Name       Type      Range      Default                                                          Description
=================  =========  =========  ===========  ===================================================================
  CalibrationFile    polflat       None    AUTOMATIC       Filename of the desired wavelength calibration file to be read
             Save        int      [0,1]            1                                1: save output on disk, 0: don't save
            gpitv        int    [0,500]            2    1-500: choose gpitv session for displaying output, 0: no display 
=================  =========  =========  ===========  ===================================================================


**IDL Filename**: pol_flat_div.pro


.. index::
    single:Rotate North Up

.. _RotateNorthUp:

Rotate North Up
---------------

 Rotate images so that north is up. 

**Category**:  SpectralScience,PolarimetricScience      **Order**: 3.9

**Inputs**:  detector image

**Outputs**: 

**Notes**:

.. code-block:: idl


    Rotate so that North is Up.


 common needed: filter, wavcal, tilt, (nlens)

 KEYWORDS:
 GEM/GPI KEYWORDS:RA,DEC,PAR_ANG
 DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,NAXIS1,NAXIS2,PC1_1,PC1_2,PC2_1,PC2_2


 HISTORY:
   2009-04-22 MDP: Created, based on DST's cubeextract_polarized.
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

========  ======  ===========  =========  ===================================================================
    Name    Type        Range    Default                                                          Description
========  ======  ===========  =========  ===================================================================
  Method    enum    CUBIC|FFT      CUBIC                                                                 None
    Show    enum          0|1          0                                                                 None
    Save     int        [0,1]          0                                                                 None
   gpitv     int      [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
========  ======  ===========  =========  ===================================================================


**IDL Filename**: rotate_north_up.pro


.. index::
    single:Rotate Field of View Square

.. _RotateFieldofViewSquare:

Rotate Field of View Square
---------------------------

 Rotate images by 26.5 degrees so that the field of view is squarely aligned with the image axes. 

**Category**:  SpectralScience,PolarimetricScience      **Order**: 3.9

**Inputs**:  detector image

**Outputs**: 

**Notes**:

.. code-block:: idl


    Rotate so that the GPI IFS field of view is roughly square with the pixel
    coordinate axes.


 common needed: filter, wavcal, tilt, (nlens)

 KEYWORDS:
 GEM/GPI KEYWORDS:RA,DEC,PAR_ANG
 DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,NAXIS1,NAXIS2,PC1_1,PC1_2,PC2_1,PC2_2


 HISTORY:
   2012-04-10 MDP: Created, based on rotate_north_up.pro

**Parameters**:

========  ======  ===========  =========  ===================================================================
    Name    Type        Range    Default                                                          Description
========  ======  ===========  =========  ===================================================================
  Method    enum    CUBIC|FFT      CUBIC                                                                 None
    crop     int        [0,1]          0                          Set to 1 to crop out non-illuminated pixels
    Show     int        [0,1]          0                                                                 None
    Save     int        [0,1]          0                                                                 None
   gpitv     int      [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
========  ======  ===========  =========  ===================================================================


**IDL Filename**: rotate_field_square.pro


.. index::
    single:Accumulate Images

.. _AccumulateImages:

Accumulate Images
-----------------

 Stores images for combination by a subsequent primitive. Can buffer on disk for datasets too large to hold just in RAM.

**Category**:  ALL      **Order**: 4.0

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**:  save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix, display

**Notes**:

.. code-block:: idl


	Stores images for later combination.

 common needed:

 KEYWORDS:


 HISTORY:
  2009-07-22: MDP started
   2009-09-17 JM: added DRF parameters

**Parameters**:

========  ========  =================  ==========  =================
    Name      Type              Range     Default        Description
========  ========  =================  ==========  =================
  Method    string    OnDisk|InMemory    InMemory    OnDisk|InMemory
========  ========  =================  ==========  =================


**IDL Filename**: accumulate_images.pro


.. index::
    single:Find Hot Pixels from a set of Darks

.. _FindHotPixelsfromasetofDarks:

Find Hot Pixels from a set of Darks
-----------------------------------

 Find hot pixels from a stack of dark images (best with deep integration darks)

**Category**:  Calibration      **Order**: 4.01

**Inputs**: Not specified

**Outputs**:       **Output Suffix**: '-hotpix'

**Notes**:

.. code-block:: idl


 This is a variant of combinedarkframes that instead writes out a
 mask showing where the various hot pixels are.


 The current algorithm determines pixels that are hot according to the
 criteria:
	(a) dark count rate must be > 1 e-/second for that pixel
	(b) that must be measured with >5 sigma confidence above the estimated
	    read noise of the frames.


 KEYWORDS:
 DRP KEYWORDS: FILETYPE,ISCALIB



 HISTORY:
   2009-07-20 JM: created
   2009-09-17 JM: added DRF parameters
   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
   2012-11-15 MP: Algorithm entirely replaced with one based on combinedarkframes.

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_find_hotpixels_from_darks.pro


.. index::
    single:Find Cold Pixels from a set of Flats

.. _FindColdPixelsfromasetofFlats:

Find Cold Pixels from a set of Flats
------------------------------------

 Find cold pixels from a stack of flat images using all different filters

**Category**:  Calibration      **Order**: 4.01

**Inputs**: Not specified

**Outputs**:       **Output Suffix**: '-coldpix'

**Notes**:

.. code-block:: idl


 This primitive finds cold (nonresponsive) pixels from the combination
 of flat fields at multiple wavelengths. This trickier than one might think,
 because it's not possible to illuminate the detector with an actual flat
 field. The best you can do is a flat through the lenslet array but that's
 still not very flat overall, with 37,000 spectra all over the place...

 Instead, we can use a clever hack: let's add up flat fields at various
 different wavelengths, and in the end we should get something that's actually
 at least got some light into all the pixels. But there's a huge ripple pattern
 everwhere.

 We then rely on the symmetry of the lenslet array to compare a given pixel to
 one that should have pretty similar flux levels, and we use that to find the
 cold pixels.


 KEYWORDS:
 DRP KEYWORDS: FILETYPE,ISCALIB



 HISTORY:
  2013-03-08 MP: Implemented in pipeline based on algorithm from Christian

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_find_coldpixels_from_flats.pro


.. index::
    single:Combine 2D dark images

.. _Combine2Ddarkimages:

Combine 2D dark images
----------------------

 Combine 2D dark images into a master file via mean or median. 

**Category**:  Calibration      **Order**: 4.01

**Inputs**:   several dark frames

**Outputs**:  master dark frame, saved as a calibration file      **Output Suffix**:  '-dark'

**Notes**:

.. code-block:: idl


  Several dark frames are combined to produce a master dark file, which
  is saved to the calibration database. This combination can be done using
  either a mean or median algorithm.

  Also, based on the variance between the various dark frames, the
  read noise is estimated, and a list of hot pixels is derived.
  The read noise and number of significantly hot pixels are written
  as keywords to the FITS header for use in trending analyses.


  TODO: more advanced combination methods. Mean, sigclip, etc.



 HISTORY:
 	 Jerome Maire 2008-10
   2009-09-17 JM: added DRF parameters
   2009-10-22 MDP: Created from mediancombine_darks, converted to use
   				accumulator.
   2010-01-25 MDP: Added support for multiple methods, MEAN method.
   2010-03-08 JM: ISCALIB flag for Calib DB
   2011-07-30 MP: Updated for multi-extension FITS

**Parameters**:

========  ======  ======================  =========  ===================================================================================
    Name    Type                   Range    Default                                                                          Description
========  ======  ======================  =========  ===================================================================================
  Method    enum    MEAN|MEDIAN|MEANCLIP     MEDIAN    How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN]
    Save     int                   [0,1]          1                                                1: save output on disk, 0: don't save
   gpitv     int                 [0,500]          2                    1-500: choose gpitv session for displaying output, 0: no display 
========  ======  ======================  =========  ===================================================================================


**IDL Filename**: combinedarkframes.pro


.. index::
    single:create Low Frequency Flat 2D

.. _createLowFrequencyFlat2D:

create Low Frequency Flat 2D
----------------------------

 Create Low Frequency Flat 2D from polarimetry flats

**Category**:  Calibration      **Order**: 4.01

**Inputs**:   Polarimetry flats

**Outputs**:  Low frequency flat      **Output Suffix**:  '-LFFlat'

**Notes**:

.. code-block:: idl


 This primitive use a combined image of polarimetry flat-fields to build a low frequency flat for the detector array.
 The idea applied here is to integrate the flux of each single spot using aperture photometry. For every spot, the neighbors are masked and the function aper computes the total flux and the sky/background correction. The neighbors are masked in order to have enough pixels to compute the sky. Then, we combine the flux of every couple of spots.
 Then, we divide all the values with their median.
 Artifacts are removed by computing a local std deviation and median. Every pixels further than n-sigma were replaced by the value of the smoothed flat.
 To finish, we interpolates the resulting values over the 2048x2048 detector array using triangulate/trigrid function (linear interpolation using nearest neighbors).

 There are still borders problem. The flat is not valid near the edges.



 HISTORY:
     Originally by Jean-Baptiste Ruffio 2013-06

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: create_2d_lf_flat.pro


.. index::
    single:Create a microphonics noise model.

.. _Createamicrophonicsnoisemodel.:

Create a microphonics noise model.
----------------------------------

 Create a microphonics noise model in Fourier space.

**Category**:  Calibration      **Order**: 4.01

**Inputs**:   several dark frames with strong microphonics

**Outputs**:  microphonics model in Fourier space, saved as a calibration file      **Output Suffix**:  '-microModel'

**Notes**:

.. code-block:: idl


  Create a microphonics noise model in Fourier space. The model consits only on the absolute value of the Fourier coefficients.
  This has to be applied after the accumulate images primitive.

  For each frame, it computes the absolute value of the Fourier coefficients around the 3 microphonics identified peaks.
  Then it combines the results of all frames based on the method defined by Combining method.
  Either adding all the models or taking the median.
  Then it normalizes the model.

  If Gauss_Interp = 1: Each of the 3 peaks is fitted by a 2d gaussian. Better not using it. It doesn't give better results.



 HISTORY:
     Originally by Jean-Baptiste Ruffio 2013-05

**Parameters**:

==================  ========  ============  =========  ===========================================================================
              Name      Type         Range    Default                                                                  Description
==================  ========  ============  =========  ===========================================================================
      Gauss_Interp       int         [0,1]          0              1: Interpolate each peak by a 2d gaussian, 0: don't interpolate
  Combining_Method    string    ADD|MEDIAN        ADD    Method to combine the Fourier transforms of the microphonics (ADD|MEDIAN)
              Save       int         [0,1]          1                                        1: save output on disk, 0: don't save
             gpitv       int       [0,500]          2            1-500: choose gpitv session for displaying output, 0: no display 
==================  ========  ============  =========  ===========================================================================


**IDL Filename**: create_microphonics_model.pro


.. index::
    single:Create Bad Pixel Map from text list of pixels

.. _CreateBadPixelMapfromtextlistofpixels:

Create Bad Pixel Map from text list of pixels
---------------------------------------------

 Generate FITS bad pixel map from a text list of pixel coords X, Y

**Category**:  Calibration      **Order**: 4.01

**Inputs**: Not specified

**Outputs**:       **Output Suffix**: bptype

**Notes**:

.. code-block:: idl


	This is kind of an oddball. This routine takes an ASCII text file containing a list of
	pixels, formatted as two columns of X and Y values, and converts it into a GPI
	calibration file format. The input FITS file is pretty much ignored entirely except
	inasmuch as it provides a header to lift some keywords from easily.

 KEYWORDS:
 DRP KEYWORDS: FILETYPE,ISCALIB



 HISTORY:
   2012-11-19 MP: New routine

**Parameters**:

=================  ========  ======================================  ============  ===================================================================
             Name      Type                                   Range       Default                                                          Description
=================  ========  ======================================  ============  ===================================================================
             Save       int                                   [0,1]             1                                1: save output on disk, 0: don't save
            gpitv       int                                 [0,500]             2    1-500: choose gpitv session for displaying output, 0: no display 
           bptype    string    hotbadpix|coldbadpix|nonlinearbadpix    coldbadpix                                      Type of bad pixel mask to write
  CalibrationFile    string                                    None     AUTOMATIC                                          Input ASCII pixel list file
=================  ========  ======================================  ============  ===================================================================


**IDL Filename**: gpi_badpixels_from_list.pro


.. index::
    single:Generate Combined Bad Pixel Map

.. _GenerateCombinedBadPixelMap:

Generate Combined Bad Pixel Map
-------------------------------

 This routine combines various sub-types of bad pixel mask (hot, cold,  anomalous nonlinear pixels) to generate a master bad pixel list.

**Category**:  Calibration      **Order**: 4.02

**Inputs**:  bad pixel maps

**Outputs**:       **Output Suffix**:  '-badpix'

**Notes**:

.. code-block:: idl


 This routine is used to combine the 3 individual types of bad pixel maps::

     Hot bad pixels
     Cold bad pixels
     Nonlinear (too nonlinear to be usable) pixels

 into one master bad pixel map.

 This is an unusual recipe, in that its input file data is not actually
 used in any way. All it does is use the first file to identify the date for
 which the bad pixel maps are generated.

 For this routine to run, there must be at least Hot and Cold bad pixel maps
 already present in the calibration DB. The nonlinear pixels map is optional.

 GEM/GPI KEYWORDS:
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
    Jerome Maire 2009-08-10
   2009-09-17 JM: added DRF parameters
   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
   2012-11-19 MP: Complete algorithm overhaul.
   2013-04-29 MP: Better error checking; nonlinearbadpix is optional.

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_combine_badpixmaps.pro


.. index::
    single:Basic ADI

.. _BasicADI:

Basic ADI
---------

 Implements the basic ADI algorithm described by Marois et al. (2006).

**Category**:  SpectralScience      **Order**: 4.1

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl

 		ADI algo based on Marois et al (2006) paper.



 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER,PAR_ANG,TELDIAM
 DRP KEYWORDS: PSFCENTX,PSFCENTY
          numimmed:  number of images for the calculation of the PSF reference
          nfwhm: number of fwhm to calculate the minimal distance for reference calculation
          save: save results (datacubes with reference subtracted and then rotated )
          gpitv: display result in gpitv session # (gpitv="0" means no display)
 EXAMPLE:
  <module name="gpi_ADIsimple_multiwav" numimmed="3" nfwhm="1.5" Save="1" gpitv="1" />
 HISTORY:
 	 Adapted for GPI - Jerome Maire 2008-08
    multiwavelength - JM
   2009-09-17 JM: added DRF parameters
    2010-04-26 JM: verify how many spectral channels to process and adapt ADI for that,
                so we can use ADI on collapsed datacubes or SDI outputs

**Parameters**:

==========  =======  =========  =========  ============================================================================
      Name     Type      Range    Default                                                                   Description
==========  =======  =========  =========  ============================================================================
  numimmed      int    [1,100]          3                     number of images for the calculation of the PSF reference
     nfwhm    float     [0,20]        1.5    number of FWHM to calculate the minimal distance for reference calculation
      Save      int      [0,1]          1                                         1: save output on disk, 0: don't save
     gpitv      int    [0,500]         10             1-500: choose gpitv session for displaying output, 0: no display 
==========  =======  =========  =========  ============================================================================


**IDL Filename**: gpi_adisimple_multiwav.pro


.. index::
    single:ADI with LOCI

.. _ADIwithLOCI:

ADI with LOCI
-------------

 Implements the LOCI ADI algorithm (Lafreniere et al. 2007)

**Category**:  SpectralScience      **Order**: 4.11

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl

 		ADI algo based on Lafreniere et al 2007.


 common needed:

 KEYWORDS:
 GEM/GPI KEYWORDS:COADDS,CRFOLLOW,DEC,EXPTIME,HA,PAR_ANG
 DRP KEYWORDS: HISTORY,PSFCENTX,PSFCENTY
          nfwhm: number of fwhm to calculate the minimal distance for reference calculation
          save: save results (datacubes with reference subtracted and then rotated )
          gpitv: display result in gpitv session # (gpitv="0" means no display)
 EXAMPLE:
  <module name="gpi_adi_Loci_multiwav" nfwhm="1.5" Save="1" gpitv="1" />


 HISTORY:
 	 Jerome Maire :- multiwavelength 2008-08
    JM: adapted for GPI-pip
   2009-09-17 JM: added DRF parameters
    2010-04-26 JM: verify how many spectral channels to process and adapt LOCI for that,
                so we can use LOCI on collapsed datacubes or SDI outputs

**Parameters**:

=======  =======  =========  =========  ============================================================================
   Name     Type      Range    Default                                                                   Description
=======  =======  =========  =========  ============================================================================
  nfwhm    float     [0,20]        1.5    number of FWHM to calculate the minimal distance for reference calculation
   Save      int      [0,1]          1                                         1: save output on disk, 0: don't save
  gpitv      int    [0,500]         10             1-500: choose gpitv session for displaying output, 0: no display 
=======  =======  =========  =========  ============================================================================


**IDL Filename**: gpi_adi_loci_multiwav.pro


.. index::
    single:Populate Shifts vs Elevation Table

.. _PopulateShiftsvsElevationTable:

Populate Shifts vs Elevation Table
----------------------------------

 Derive shifts vs elevation lookup table.

**Category**:  Calibration      **Order**: 4.2

**Inputs**:  wavecal

**Outputs**:       **Output Suffix**:  '-shifts'

**Notes**:

.. code-block:: idl


	This function produces the table of spectral position shifts vs
	elevation angle used to compensate for flexure within the GPI IFS.

	It takes as input a series of reduced wavelength calibration
	files. It compares them against a reference wavelength calibration file
	obtained from the calibration database (which must have been taken in
	horizontal orientation).  The shift in X and Y positions are calculated
	for each lenslet, and then the mean over the entire field is taken.

	The median X shift and Y shift for each elevation is saved into
	a table in the calibration database.


   Optionally the user can request diagnostic plots displayed on screen or
   saved to disk as postscript files.


 ALGORITHM:


 common needed:

 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP,GCALSHUT,OBSTYPE
 DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB


 HISTORY:
      Jerome Maire 2013-02

**Parameters**:

===========  ========  ==========  =========  ===========================================================
       Name      Type       Range    Default                                                  Description
===========  ========  ==========  =========  ===========================================================
       Save       int       [0,1]          1                        1: save output on disk, 0: don't save
    display    string    [yes|no]        yes                  Show diagnostic plot when running? [yes|no]
  saveplots    string    [yes|no]         no    Save diagnostic plots to PS files after running? [yes|no]
===========  ========  ==========  =========  ===========================================================


**IDL Filename**: gpi_populate_shifts_elev_table.pro


.. index::
    single:Combine Wavelength Calibrations locations

.. _CombineWavelengthCalibrationslocations:

Combine Wavelength Calibrations locations
-----------------------------------------

 Combine wavelength calibration from  flat and arc

**Category**:  Calibration      **Order**: 4.2

**Inputs**:  3D wavcal

**Outputs**: 

**Notes**:

.. code-block:: idl


 gpi_combine_wavcal_all is a simple median combination of wav. cal. files obtained with flat and arc images.
  TO DO: exclude some mlens from the median in case of  wavcal


 GEM/GPI KEYWORDS:FILTER,IFSFILT
 DRP KEYWORDS: DATAFILE, DATE-OBS,TIME-OBS


 HISTORY:
    Jerome Maire 2009-08-10
   2009-09-17 JM: added DRF parameters
   2012-10-17 MP: Removed deprecated suffix= keyword

**Parameters**:

============  ======  =========  =========  ===================================================================
        Name    Type      Range    Default                                                          Description
============  ======  =========  =========  ===================================================================
  polydegree     int      [1,2]          1                1: linear wavelength solution, 2: quadratic wav. sol.
        Save     int      [0,1]          1                                1: save output on disk, 0: don't save
       gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
============  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_combine_wavcal_locations_all.pro


.. index::
    single:Combine Wavelength Calibrations

.. _CombineWavelengthCalibrations:

Combine Wavelength Calibrations
-------------------------------

 Performs simple median combination of wavelength calibrations from flat and/or arc lamps

**Category**:  Calibration      **Order**: 4.2

**Inputs**:  3D wavcal

**Outputs**: 

**Notes**:

.. code-block:: idl


 gpi_combine_wavcal_all is a simple median combination of wav. cal. files obtained with flat and arc images.
  TO DO: exclude some mlens from the median in case of  wavcal


 GEM/GPI KEYWORDS:DATE-OBS,FILTER,IFSFILT,TIME-OBS
 DRP KEYWORDS: DATAFILE


 HISTORY:
    Jerome Maire 2009-08-10
   2009-09-17 JM: added DRF parameters
   2012-10-17 MP: Removed deprecated suffix= keyword

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_combine_wavcal_all.pro


.. index::
    single:Simple SSDI of median ADI residual

.. _SimpleSSDIofmedianADIresidual:

Simple SSDI of median ADI residual
----------------------------------

 Apply SSDI to create a 2D subtracted image from a cube. Given the user's specified wavelength ranges, extract the 3D datacube slices for each of those wavelength ranges. Collapse these down into 2D images by simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1, then compute  diffImage = I1scaled - k* I2

**Category**:  SpectralScience      **Order**: 4.3

**Inputs**: 

**Outputs**:       **Output Suffix**:  save_currdata( DataSet,  Modules[thisModuleIndex].OutputDir, suffix+'-sssd', savedata

**Notes**:

.. code-block:: idl


 		This recipe rescales and subtracts 2 frames in different user-defined bandwidths. This recipe is used for speckle suppression using the Marois et al (2000) algorithm.

		This routine does NOT update the data structures in memory. You **MUST**
		set the keyword SAVE=1 or else the output is silently discarded.

 	input datacube
 	wavelength solution from common block

 KEYWORDS:
 	L1Min=		Wavelength range 1, minimum wavelength [in microns]
 	L1Max=		Wavelength range 1, maximum wavelength [in microns]
 	L2Min=		Wavelength range 2, minimum wavelength [in microns]
 	L2Max=		Wavelength range 2, maximum wavelength [in microns]
 	k=			Multiplicative coefficient for multiplying the image for
 				Wavelength Range *2*. Default value is k=1.

 	/Save		Set to 1 to save the output file to disk


 ALGORITHM:
	Given the user's specified wavelength ranges, extract the 3D datacube slices
	for each of those wavelength ranges. Collapse these down into 2D images by
	simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1
	using fftscale so that the PSF scale matches that of Image2 (as computed
	from the average wavelength for each image). Then compute
	   diffImage = I1scaled - k* I2
	Then hopefully output the image somewhere if SAVE=1 is set.



 HISTORY:
 	2007-11 Jerome Maire
	2009-04-15 MDP: Documentation updated; slight code cleanup
    2009-09-17 JM: added DRF parameters

**Parameters**:

=======  =======  ===========  =========  ===========================================================================
   Name     Type        Range    Default                                                                  Description
=======  =======  ===========  =========  ===========================================================================
  L1Min    float    [0.9,2.5]       1.55                          Wavelength range 1, minimum wavelength [in microns]
  L1Max    float    [0.9,2.5]       1.57                          Wavelength range 1, maximum wavelength [in microns]
  L2Min    float    [0.9,2.5]       1.60                          Wavelength range 2, minimum wavelength [in microns]
  L2Max    float    [0.9,2.5]       1.65                          Wavelength range 2, maximum wavelength [in microns]
      k    float       [0,10]        1.0    Scaling factor of Intensity(wav_range2) with diffImage = I1scaled - k* I2
   Save      int        [0,1]          1                                        1: save output on disk, 0: don't save
  gpitv      int      [0,500]          5            1-500: choose gpitv session for displaying output, 0: no display 
=======  =======  ===========  =========  ===========================================================================


**IDL Filename**: simplespectraldiff_postadi.pro


.. index::
    single:Combine Polarization Sequence

.. _CombinePolarizationSequence:

Combine Polarization Sequence
-----------------------------



**Category**:  PolarimetricScience,Calibration      **Order**: 4.4

**Inputs**: 

**Outputs**: Not specified      **Output Suffix**:  "-stokesdc"

**Notes**:

.. code-block:: idl


	Combine a sequence of polarized images via the SVD method.

	See James Graham's SVD algorithm document, or this algorithm may be hard to
	follow.  This is not your father's imaging polarimeter any more!

 	This routine assumes that it can read in a series of files on disk which were written by
 	the previous stage of processing.



 GEM/GPI KEYWORDS:EXPTIME,ISS_PORT,PAR_ANG,WPANGLE
 DRP KEYWORDS:CDELT3,CRPIX3,CRVAL3,CTYPE3,CUNIT3,DATAFILE,NAXISi,PC3_3
 ALGORITHM:





 HISTORY:
  2009-07-21: MDP Started
    2009-09-17 JM: added DRF parameters
    2013-01-30: updated with some new keywords

**Parameters**:

======================  =======  ==============  =========  ===================================================================
                  Name     Type           Range    Default                                                          Description
======================  =======  ==============  =========  ===================================================================
             HWPoffset    float    [-360.,360.]     -29.14                  The internal offset of the HWP. If unknown set to 0
  IncludeSystemMueller      int           [0,1]          1                                                 1: Include, 0: Don't
                  Save      int           [0,1]          1                                1: save output on disk, 0: don't save
                 gpitv      int         [0,500]         10    1-500: choose gpitv session for displaying output, 0: no display 
======================  =======  ==============  =========  ===================================================================


**IDL Filename**: pol_combine.pro


.. index::
    single:Median ADI data-cubes

.. _MedianADIdata-cubes:

Median ADI data-cubes
---------------------

 Median all residual ADI (or LOCI) data-cubes.

**Category**:  SpectralScience      **Order**: 4.5

**Inputs**:  data-cube

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


     Median all ADI datacubes


 common needed:

 KEYWORDS:

 EXAMPLE:
  <module name="gpi_medianADI"  Save="1" gpitv="1" />
 HISTORY:
    Jerome Maire :- multiwavelength 2008-08
    JM: adapted for GPI-pip
   2009-09-17 JM: added DRF parameters
   2010-10-19 JM: split HISTORY keyword if necessary

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]         10    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_medianadi.pro


.. index::
    single:Combine 3D cubes

.. _Combine3Dcubes:

Combine 3D cubes
----------------

 Combine 3D data cubes via mean or median. 

**Category**:  ALL      **Order**: 4.5

**Inputs**:  3d datacubes

**Outputs**:  a single combined datacube      **Output Suffix**:  strlowcase(method)

**Notes**:

.. code-block:: idl


  Multiple 3D cubes can be combined into one, using either a Mean or a Median.

  TODO: more advanced combination methods. sigma-clipped mean should be
  implemented, etc.



 HISTORY:
 	 Jerome Maire 2008-10
   2009-09-17 JM: added DRF parameters
   2009-10-22 MDP: Created from mediancombine_darks, converted to use
   				accumulator.
   2010-01-25 MDP: Added support for multiple methods, MEAN method.
   2011-07-30 MP: Updated for multi-extension FITS
   2012-10-10 MP: Minor code cleanup

**Parameters**:

==========  ======  ==============================  =========  ======================================================================
      Name    Type                           Range    Default                                                             Description
==========  ======  ==============================  =========  ======================================================================
    Method    enum    MEAN|MEDIAN|MEANCLIP|MINIMUM     MEDIAN    How to combine images: median, mean, or mean with outlier rejection?
  sig_clip     int                            0,10          3               Clipping value to be used with MEANCLIP in sigma (stddev)
      Save     int                           [0,1]          1                                   1: save output on disk, 0: don't save
     gpitv     int                         [0,500]          2       1-500: choose gpitv session for displaying output, 0: no display 
==========  ======  ==============================  =========  ======================================================================


**IDL Filename**: combine_3dcubes.pro


.. index::
    single:Set Calibration Type

.. _SetCalibrationType:

Set Calibration Type
--------------------

  Set calibration type for recording a reduced calibration observation into the cal DB. 

**Category**:  Calibration      **Order**: 9.9

**Inputs**:  datacube

**Outputs**: Not specified      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


   Mark an output file as a calibration file, manually.

	**Deprecated / unnecessary - most/all routines that create calibration files
	do this automatically as part of the data processing.**
	As of July 2013 this does not appear to be used anywhere. -MP


 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
 	2011-08-01 MP: Updated for multi-extension FITS
 	2013-07-10 MP: Documentation update. Added deprecation note.

**Parameters**:

==========  ======  =========  =========  ===================================================================
      Name    Type      Range    Default                                                          Description
==========  ======  =========  =========  ===================================================================
  filetype    None       None       Dark                                                Calibration File Type
      save     int      [0,1]          1                                1: save output on disk, 0: don't save
     gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
==========  ======  =========  =========  ===================================================================


**IDL Filename**: set_calfile_type.pro


.. index::
    single:Save Output

.. _SaveOutput:

Save Output
-----------

 Save output to disk as a FITS file. Note that you can often do this from another module by setting the 'save=1' option; this is a redundant way to specify that. 

**Category**:  ALL      **Order**: 10.0

**Inputs**:  data-cube

**Outputs**:   datacube with slice at the same wavelength      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	Save the current dataset to disk. Note that you can often do this
	from another module by setting the 'save=1' option; this is a
	redundant way to specify that.

	Note that this uses whatever the currently defined suffix is, though you can
	also override that here.  This is the one and only routine that should be
	used to override a suffix.

  TODO: change output filename too, optionally?



 KEYWORDS:



 HISTORY:
	2009-07-21 Created by MDP.
   2009-09-17 JM: added DRF parameters

**Parameters**:

========  ======  =========  =========  ===================================================================
    Name    Type      Range    Default                                                          Description
========  ======  =========  =========  ===================================================================
  suffix    None       None       None                                                    choose the suffix
    Save     int      [0,1]          1                                1: save output on disk, 0: don't save
   gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
========  ======  =========  =========  ===================================================================


**IDL Filename**: save_output.pro


