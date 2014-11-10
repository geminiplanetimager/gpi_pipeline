.. _primitives:

Primitives, Listed by Category
==============================




This page documents all available pipeline primitives, currently 100 in total. 

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
Order  Primitives relevant to SpectralScience     (47 total)
====== ======================================================================================================================================================================== =
 0.01  :ref:`Display raw image with GPItv <DisplayrawimagewithGPItv>`
 0.10  :ref:`Flag Quicklook <FlagQuicklook>`
 0.50  :ref:`Load Wavelength Calibration <LoadWavelengthCalibration>`
 0.90  :ref:`Check Data Quality <CheckDataQuality>`
 1.10  :ref:`Subtract Dark Background <SubtractDarkBackground>`
 1.20  :ref:`Subtract Thermal/Sky Background if K band <SubtractThermal/SkyBackgroundifKband>`
 1.20  :ref:`Remove Persistence from Previous Images <RemovePersistencefromPreviousImages>`
 1.25  :ref:`Apply Reference Pixel Correction <ApplyReferencePixelCorrection>`
 1.34  :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
 1.35  :ref:`Destripe science image <Destripescienceimage>`
 1.40  :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`
 1.50  :ref:`Combine 2D images <Combine2Dimages>`
 2.00  :ref:`Assemble Spectral Datacube <AssembleSpectralDatacube>`
 2.00  :ref:`Assemble Spectral Datacube (bp) <AssembleSpectralDatacube(bp)>`
 2.20  :ref:`Divide by Lenslet Flat Field <DividebyLensletFlatField>`
 2.20  :ref:`Divide by Spectral Flat Field <DividebySpectralFlatField>`
 2.30  :ref:`Interpolate Wavelength Axis <InterpolateWavelengthAxis>`
 2.35  :ref:`Subtract Thermal/Sky Background Cube if K band <SubtractThermal/SkyBackgroundCubeifKband>`
 2.41  :ref:`Check for closed-loop coronagraphic image <Checkforclosed-loopcoronagraphicimage>`
 2.44  :ref:`Correct Distortion <CorrectDistortion>`
 2.44  :ref:`Measure satellite spot locations <Measuresatellitespotlocations>`
 2.45  :ref:`Measure satellite spot peak fluxes <Measuresatellitespotpeakfluxes>`
 2.50  :ref:`Interpolate bad pixels in cube <Interpolatebadpixelsincube>`
 2.51  :ref:`Extract one spectrum, plots <Extractonespectrum,plots>`
 2.51  :ref:`Calibrate Photometric Flux <CalibratePhotometricFlux>`
 2.52  :ref:`Extract 1D spectrum from a datacube <Extract1Dspectrumfromadatacube>`
 2.60  :ref:`Collapse datacube <Collapsedatacube>`
 2.61  :ref:`Speckle alignment <Specklealignment>`
 2.61  :ref:`Simple Spectral Differential Imaging <SimpleSpectralDifferentialImaging>`
 2.70  :ref:`Plot the satellite spot locations vs. the expected location from wavelength scaling <Plotthesatellitespotlocationsvs.theexpectedlocationfromwavelengthscaling>`
 2.70  :ref:`Measure Contrast <MeasureContrast>`
 2.80  :ref:`KLIP algorithm Spectral Differential Imaging <KLIPalgorithmSpectralDifferentialImaging>`
 2.90  :ref:`Update World Coordinates <UpdateWorldCoordinates>`
 3.50  :ref:`Smooth a 3D Cube <Smootha3DCube>`
 3.90  :ref:`Rotate North Up <RotateNorthUp>`
 3.90  :ref:`Rotate Field of View Square <RotateFieldofViewSquare>`
 4.00  :ref:`Accumulate Images <AccumulateImages>`
 4.10  :ref:`Basic ADI <BasicADI>`
 4.11  :ref:`ADI with LOCI <ADIwithLOCI>`
 4.20  :ref:`KLIP algorithm Angular Differential Imaging <KLIPalgorithmAngularDifferentialImaging>`
 4.20  :ref:`KLIP algorithm Angular Differential Imaging With Center Forced <KLIPalgorithmAngularDifferentialImagingWithCenterForced>`
 4.30  :ref:`Simple SDI of post ADI residual <SimpleSDIofpostADIresidual>`
 4.50  :ref:`Median Combine ADI datacubes <MedianCombineADIdatacubes>`
 4.50  :ref:`Combine 3D Datacubes <Combine3DDatacubes>`
 5.00  :ref:`Insert Planet into datacube <InsertPlanetintodatacube>`
10.00  :ref:`Save Output <SaveOutput>`
====== ======================================================================================================================================================================== =



.. _PolarimetricScience:

PolarimetricScience
-------------------

====== ============================================================================================================== =
Order  Primitives relevant to PolarimetricScience     (36 total)
====== ============================================================================================================== =
 0.01  :ref:`Display raw image with GPItv <DisplayrawimagewithGPItv>`
 0.10  :ref:`Flag Quicklook <FlagQuicklook>`
 0.51  :ref:`Load Polarimetry Spot Calibration <LoadPolarimetrySpotCalibration>`
 0.52  :ref:`Load Instrumental Polarization Calibration <LoadInstrumentalPolarizationCalibration>`
 0.90  :ref:`Check Data Quality <CheckDataQuality>`
 1.10  :ref:`Subtract Dark Background <SubtractDarkBackground>`
 1.20  :ref:`Remove Persistence from Previous Images <RemovePersistencefromPreviousImages>`
 1.20  :ref:`Subtract Thermal/Sky Background if K band <SubtractThermal/SkyBackgroundifKband>`
 1.25  :ref:`Apply Reference Pixel Correction <ApplyReferencePixelCorrection>`
 1.34  :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
 1.35  :ref:`Destripe science image <Destripescienceimage>`
 1.40  :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`
 1.50  :ref:`Combine 2D images <Combine2Dimages>`
 2.00  :ref:`Assemble Polarization Cube <AssemblePolarizationCube>`
 2.20  :ref:`Divide by Lenslet Flat Field <DividebyLensletFlatField>`
 2.35  :ref:`Subtract Thermal/Sky Background Cube if K band <SubtractThermal/SkyBackgroundCubeifKband>`
 2.41  :ref:`Check for closed-loop coronagraphic image <Checkforclosed-loopcoronagraphicimage>`
 2.44  :ref:`Correct Distortion <CorrectDistortion>`
 2.44  :ref:`Measure Star Position for Polarimetry <MeasureStarPositionforPolarimetry>`
 2.50  :ref:`Interpolate bad pixels in cube <Interpolatebadpixelsincube>`
 2.60  :ref:`Collapse datacube <Collapsedatacube>`
 2.70  :ref:`Measure Contrast <MeasureContrast>`
 2.90  :ref:`Update World Coordinates <UpdateWorldCoordinates>`
 3.50  :ref:`Divide by Polarized Flat Field <DividebyPolarizedFlatField>`
 3.50  :ref:`Smooth a 3D Cube <Smootha3DCube>`
 3.90  :ref:`Rotate Field of View Square <RotateFieldofViewSquare>`
 3.90  :ref:`Rotate North Up <RotateNorthUp>`
 4.00  :ref:`Accumulate Images <AccumulateImages>`
 4.05  :ref:`Clean Polarization Pairs via Double Difference <CleanPolarizationPairsviaDoubleDifference>`
 4.20  :ref:`Advanced KLIP ADI for Pol Mode <AdvancedKLIPADIforPolMode>`
 4.20  :ref:`KLIP ADI for Pol Mode <KLIPADIforPolMode>`
 4.40  :ref:`Combine Polarization Sequence via Double Difference <CombinePolarizationSequenceviaDoubleDifference>`
 4.40  :ref:`Combine Polarization Sequence <CombinePolarizationSequence>`
 4.50  :ref:`Combine 3D Datacubes <Combine3DDatacubes>`
 5.00  :ref:`Subtract Mean Stellar Polarization <SubtractMeanStellarPolarization>`
10.00  :ref:`Save Output <SaveOutput>`
====== ============================================================================================================== =



.. _Calibration:

Calibration
-----------

====== ========================================================================================================================== =
Order  Primitives relevant to Calibration     (61 total)
====== ========================================================================================================================== =
 0.01  :ref:`Display raw image with GPItv <DisplayrawimagewithGPItv>`
 0.10  :ref:`Flag Quicklook <FlagQuicklook>`
 0.50  :ref:`Load Wavelength Calibration <LoadWavelengthCalibration>`
 0.51  :ref:`Load Polarimetry Spot Calibration <LoadPolarimetrySpotCalibration>`
 0.52  :ref:`Load Instrumental Polarization Calibration <LoadInstrumentalPolarizationCalibration>`
 0.90  :ref:`Check Data Quality <CheckDataQuality>`
 1.10  :ref:`Subtract Dark Background <SubtractDarkBackground>`
 1.20  :ref:`Remove Persistence from Previous Images <RemovePersistencefromPreviousImages>`
 1.20  :ref:`Subtract Thermal/Sky Background if K band <SubtractThermal/SkyBackgroundifKband>`
 1.25  :ref:`Apply Reference Pixel Correction <ApplyReferencePixelCorrection>`
 1.34  :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
 1.35  :ref:`Destripe for Darks Only <DestripeforDarksOnly>`
 1.35  :ref:`Destripe science image <Destripescienceimage>`
 1.40  :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`
 1.50  :ref:`Combine 2D images <Combine2Dimages>`
 1.51  :ref:`Combine 2D Thermal/Sky Backgrounds <Combine2DThermal/SkyBackgrounds>`
 1.70  :ref:`Measure Wavelength Calibration <MeasureWavelengthCalibration>`
 1.70  :ref:`2D Wavelength Solution <2DWavelengthSolution>`
 1.70  :ref:`Quick Wavelength Solution Update <QuickWavelengthSolutionUpdate>`
 1.80  :ref:`Measure Polarization Spot Calibration <MeasurePolarizationSpotCalibration>`
 2.00  :ref:`Assemble Polarization Cube <AssemblePolarizationCube>`
 2.00  :ref:`Assemble Undispersed Image <AssembleUndispersedImage>`
 2.00  :ref:`Assemble Spectral Datacube <AssembleSpectralDatacube>`
 2.20  :ref:`Divide by Lenslet Flat Field <DividebyLensletFlatField>`
 2.20  :ref:`Divide by Spectral Flat Field <DividebySpectralFlatField>`
 2.25  :ref:`Remove Flat Lamp spectrum <RemoveFlatLampspectrum>`
 2.30  :ref:`Interpolate Wavelength Axis <InterpolateWavelengthAxis>`
 2.35  :ref:`Subtract Thermal/Sky Background Cube if K band <SubtractThermal/SkyBackgroundCubeifKband>`
 2.41  :ref:`Check for closed-loop coronagraphic image <Checkforclosed-loopcoronagraphicimage>`
 2.44  :ref:`Measure satellite spot locations <Measuresatellitespotlocations>`
 2.44  :ref:`Measure GPI distortion from grid pattern <MeasureGPIdistortionfromgridpattern>`
 2.44  :ref:`Measure Star Position for Polarimetry <MeasureStarPositionforPolarimetry>`
 2.45  :ref:`Measure satellite spot peak fluxes <Measuresatellitespotpeakfluxes>`
 2.50  :ref:`Interpolate bad pixels in cube <Interpolatebadpixelsincube>`
 2.60  :ref:`Collapse datacube <Collapsedatacube>`
 2.60  :ref:`Calibrate astrometry from binary (using separation and PA) <Calibrateastrometryfrombinary(usingseparationandPA)>`
 2.61  :ref:`Calibrate astrometry from binary (using 6th orbit catalog) <Calibrateastrometryfrombinary(using6thorbitcatalog)>`
 2.90  :ref:`Update World Coordinates <UpdateWorldCoordinates>`
 3.00  :ref:`Stores calibration in dataset <Storescalibrationindataset>`
 3.20  :ref:`Create Lenslet Flat Field <CreateLensletFlatField>`
 3.20  :ref:`Normalize polarimetry flat field <Normalizepolarimetryflatfield>`
 3.50  :ref:`Divide by Polarized Flat Field <DividebyPolarizedFlatField>`
 3.50  :ref:`Smooth a 3D Cube <Smootha3DCube>`
 4.00  :ref:`Accumulate Images <AccumulateImages>`
 4.01  :ref:`Combine 2D dark images <Combine2Ddarkimages>`
 4.01  :ref:`Find Hot Bad Pixels from Darks <FindHotBadPixelsfromDarks>`
 4.01  :ref:`Create microphonics noise model <Createmicrophonicsnoisemodel>`
 4.01  :ref:`Creates a thermal/sky background datacube <Createsathermal/skybackgrounddatacube>`
 4.01  :ref:`Find Cold Bad Pixels from Flats <FindColdBadPixelsfromFlats>`
 4.02  :ref:`Generate Combined Bad Pixel Map <GenerateCombinedBadPixelMap>`
 4.05  :ref:`Clean Polarization Pairs via Double Difference <CleanPolarizationPairsviaDoubleDifference>`
 4.20  :ref:`Populate Flexure Shifts vs Elevation Table <PopulateFlexureShiftsvsElevationTable>`
 4.20  :ref:`Combine Wavelength Calibrations locations <CombineWavelengthCalibrationslocations>`
 4.20  :ref:`Combine Wavelength Calibrations <CombineWavelengthCalibrations>`
 4.40  :ref:`Combine Polarization Sequence via Double Difference <CombinePolarizationSequenceviaDoubleDifference>`
 4.40  :ref:`Combine Polarization Sequence <CombinePolarizationSequence>`
 4.50  :ref:`Quality Check Wavelength Calibration <QualityCheckWavelengthCalibration>`
 4.50  :ref:`Combine 3D Datacubes <Combine3DDatacubes>`
 4.60  :ref:`Pad Wavelength Calibration Edges <PadWavelengthCalibrationEdges>`
10.00  :ref:`Save Output <SaveOutput>`
====== ========================================================================================================================== =


Primitive Detailed Documentation
==================================


.. index::
    single:Display raw image with GPItv

.. _DisplayrawimagewithGPItv:

Display raw image with GPItv
----------------------------

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
   2013-07-12 MP: Rename for consistency

**Parameters**:

=======  ======  =========  =========  ======================================================================
   Name    Type      Range    Default                                                             Description
=======  ======  =========  =========  ======================================================================
  gpitv     int    [0,500]          1    1-500: choose gpitv session for displaying output, 0 for no display 
=======  ======  =========  =========  ======================================================================


**IDL Filename**: gpi_display_raw_image_with_gpitv.pro


.. index::
    single:Flag Quicklook

.. _FlagQuicklook:

Flag Quicklook
--------------

 Flag a given reduction output as 'quicklook' quality rather than science grade.

**Category**:  ALL      **Order**: 0.1

**Inputs**: Not specified

**Outputs**:  The FITS file header in memory gets added a keyword QUIKLOOK=True

**Notes**:

.. code-block:: idl


	Writes a QUIKLOOK=True keyword to the current header.
	Also updates some FITS history text to indicate the quicklook status.



 HISTORY:
    Marshall Perrin 2013-10-29  Started based on gpi_add_missingkeyword

**Parameters**:

======  ======  =======  =========  =======================================
  Name    Type    Range    Default                              Description
======  ======  =======  =========  =======================================
  Save     int    [0,1]          0    1: Save output to disk, 0: Don't save
======  ======  =======  =========  =======================================


**IDL Filename**: gpi_flag_quicklook.pro



.. index::
    single:Load Wavelength Calibration

.. _LoadWavelengthCalibration:

Load Wavelength Calibration
---------------------------

 Reads a wavelength calibration file from disk. This primitive is required for any data-cube extraction.

**Category**:  SpectralScience,Calibration      **Order**: 0.5

**Inputs**:  none

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
   2013-07-10 MP: Documentation update and code cleanup
   2013-07-16 MP: Rename file for consistency
   2013-12-02 JM: get ELEVATIO and INPORT for later flexure correction
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =======  ===========  ================================================================
             Name      Type    Range      Default                                                       Description
=================  ========  =======  ===========  ================================================================
  CalibrationFile    String     None    AUTOMATIC    Filename of the desired wavelength calibration file to be read
=================  ========  =======  ===========  ================================================================


**IDL Filename**: gpi_load_wavelength_calibration.pro


.. index::
    single:Load Polarimetry Spot Calibration

.. _LoadPolarimetrySpotCalibration:

Load Polarimetry Spot Calibration
---------------------------------

 Reads a pol spot calibration file from disk. This primitive is required for any polarimetry data-cube extraction.

**Category**:  PolarimetricScience,Calibration      **Order**: 0.51

**Inputs**:  Not used directly

**Outputs**:  none; polarimetry spot cal file is loaded into memory

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
   2013-07-17 MP:  Rename for consistency
   2013-12-16 MP:  CalibrationFile argument syntax update.
   2014-03-21 MP:  Remove 'efficient' code for avoiding reloading, since
					this doesn't play well with flexure updates that shift
					the calibrations all around.

**Parameters**:

=================  ========  =======  ===========  ================================================================
             Name      Type    Range      Default                                                       Description
=================  ========  =======  ===========  ================================================================
  CalibrationFile    String     None    AUTOMATIC    Filename of the desired wavelength calibration file to be read
=================  ========  =======  ===========  ================================================================


**IDL Filename**: gpi_load_polarimetry_spot_calibration.pro


.. index::
    single:Load Instrumental Polarization Calibration

.. _LoadInstrumentalPolarizationCalibration:

Load Instrumental Polarization Calibration
------------------------------------------

 Load a calibration file for the instrumental polarization.

**Category**:  PolarimetricScience,Calibration      **Order**: 0.52

**Inputs**: Not specified

**Outputs**:   Instrumental polarization calibration is loaded into memory

**Notes**:

.. code-block:: idl





 HISTORY:
 	2010-05-22 MDP: started
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-30 MP: Updated for multi-extension FITS
   2013-07-16 MP: Renamed for consistency
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =======  ===========  ===================================================================
             Name      Type    Range      Default                                                          Description
=================  ========  =======  ===========  ===================================================================
  CalibrationFile    String     None    AUTOMATIC    Filename of the desired instrumental polarization file to be read
=================  ========  =======  ===========  ===================================================================


**IDL Filename**: gpi_load_instrumental_polarization_calibration.pro


.. index::
    single:Check Data Quality

.. _CheckDataQuality:

Check Data Quality
------------------

 Check quality of data based on header keywords. For bad data, can fail the reduction or simply alert the user.

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
   2013-07-16 MP: Documentation cleanup. Rename 'control_data_quality' -> 'check_data_quality'



**Parameters**:

========  =======  ==========  =========  ==========================================================
    Name     Type       Range    Default                                                 Description
========  =======  ==========  =========  ==========================================================
  Action      int      [0,10]          1    0:Simple alert and continue reduction, 1:Reduction fails
      r0    float       [0,2]       0.08                        critical r0 [m] at lambda=0.5microns
  rmserr    float    [0,1000]        10.                   Critical rms wavefront error in microns. 
========  =======  ==========  =========  ==========================================================


**IDL Filename**: gpi_check_data_quality.pro


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


	 Subtract background from an image using a dark file.

	 If CalibrationFile=AUTOMATIC, the best available dark is
	 obtained from the calibration database.
    "Best dark" generally means a dark file that has the most similar
    integration time and is closest in date & time of observation
    to the data in question.

    Specifically, in the Calibration Database code for darks,
    the algorithm first looks for dark files which are between
    0.3 and 3x of the desired integration time. It takes all such
    darks which are on the closest date of observation to the
    science data, and from those finds the one that is closest in
    integration time to the science data.

    This dark is read in, rescaled by the appropriate ratio of
    integration times, and then subtracted from the data.



	 Empirically, rescaling darks by too large a factor does not
	 result in very high quality subtractions, due to various nonlinear
	 behaviors such as saturation of hot pixels and the so-called
	 'reset anomaly' effect which biases the readout background level.
	 Hence we impose a limit for scaling the dark integration time
	 up or down, semi-arbitrarily chosen to be 3x because it seems to
	 work reasonably well.  The standard set of darks planned to be
	 taken routinely at Gemini should ensure that there are always available
	 darks within this range.

	 If you desire different behavior, simply set the CalibrationFile manually
	 of course.


	 Note: If the RequireExactMatch setting is 1, then only dark files
		exactly matching in integration time will be used. If there is no
		such file, the data is returned without any subtraction.





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
	2013-10-03 MP: Add RequireExactMatch option, enable scaling for non-matching exptimes
   2013-12-16 MP: CalibrationFile argument syntax update.
   2014-03-22 MP: Adding experimental interpolation option.


**Parameters**:

===================  ========  =========  ===========  =====================================================================================================================
               Name      Type      Range      Default                                                                                                            Description
===================  ========  =========  ===========  =====================================================================================================================
    CalibrationFile    string       None    AUTOMATIC                                                                                          Name of dark file to subtract
  RequireExactMatch       int      [0,1]            0    Must dark calibration file exactly match in integration time, or is scaling from a different exposure time allowed?
        Interpolate       int      [0,1]            0                                                   Interpolate based on JD between prior and subsequent available darks
               Save       int      [0,1]            0                                                                                  1: save output on disk, 0: don't save
              gpitv       int    [0,500]            0                                                      1-500: choose gpitv session for displaying output, 0: no display 
===================  ========  =========  ===========  =====================================================================================================================


**IDL Filename**: gpi_subtract_dark_background.pro


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
   2013-07-12 MP: Rename for consistency
   2013-12-15 MP: Add override_scaling option, remove erroneous hard-coded
					constant non-1 scaling.
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

==================  ========  =========  ===========  =================================================================================================================
              Name      Type      Range      Default                                                                                                        Description
==================  ========  =========  ===========  =================================================================================================================
   CalibrationFile    string       None    AUTOMATIC                                                                        Name of thermal background file to subtract
              Save       int      [0,1]            0                                                                              1: save output on disk, 0: don't save
  Override_scaling     float     [0,10]          1.0    Set to value other than 1 to manually adjust the background image flux scaling to better match the science data
             gpitv       int    [0,500]            0                                                  1-500: choose gpitv session for displaying output, 0: no display 
==================  ========  =========  ===========  =================================================================================================================


**IDL Filename**: gpi_subtract_thermal_sky_background_if_k_band.pro


.. index::
    single:Remove Persistence from Previous Images

.. _RemovePersistencefromPreviousImages:

Remove Persistence from Previous Images
---------------------------------------

 Determines/Removes persistence of previous images

**Category**:  ALL      **Order**: 1.2

**Inputs**:  Raw or destriped 2D image

**Outputs**:  2D image corrected for persistence of previous non-saturated images      **Output Suffix**:  '-nopersis'

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
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    String       None    AUTOMATIC                Filename of the persistence_parameter file to be read
             Save       int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: gpi_remove_persistence_from_previous_images.pro


.. index::
    single:Clean Cosmic Rays

.. _CleanCosmicRays:

Clean Cosmic Rays
-----------------

 Placeholder for cosmic ray rejection (if needed; not currently implemented!)

**Category**:  HIDDEN      **Order**: 1.23

**Inputs**: Not specified

**Outputs**: Not specified

**Notes**:

.. code-block:: idl


   Placeholder; does not actually do anything yet.
   Empirically, cosmic rays do not appear to be a significant noise source
   for the GPI IFS. It's a substrate-removed H2RG so the level is quite low.
   Furthermore, realtime identification and removal of CRs is included as
   part of the up-the-ramp readout and slope fitting, which handles the
   majority of CRs.


   There are still occasional noticeable residual CRs, particularly in long
   duration exposures or darks, but they've not yet proven annoying enough to
   implement an algorithm here...



 HISTORY:
 2010-01-28 MDP: Created Templae.
 2011-07-30 MDP: Updated for multi-extension FITS
 2013-07-16 MDP: Renamed as part of code cleanup.

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          0                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_clean_cosmic_rays.pro


.. index::
    single:Apply Reference Pixel Correction

.. _ApplyReferencePixelCorrection:

Apply Reference Pixel Correction
--------------------------------

 Subtract channel bias levels and bias drift stripes using H2RG reference pixels.

**Category**:  ALL      **Order**: 1.25

**Inputs**:  2D image file

**Outputs**:  2D image corrected for background using reference pixels      **Output Suffix**:  'refpixcorr'

**Notes**:

.. code-block:: idl


 	Correct for fluctuations in the bias/dark level using the rows of
 	reference pixels in the H2RG detectors.

   Note that *vertical* reference pixel subtraction to fix offsets between
   the 32 readout channels is done in real time during the readout process by
   the IFS Detector Server software. The Detector Server does not currently
   apply any horizontal reference pixel subtraction, so we need to do that in
   the pipeline. See the HRPSTYPE and VRPSTYPE FITS keywords in the SCI
   extension headers.

	Also note that if you use one of the specialized Destriping primitives,
	you do not also need to use this one as well.


   Algorithm choices include:
    1) simple_channels		in this case, just use the median of each
    					    vertical channel to remove offsets between
    					    the channels. (deprecated, now done by the IFS
    					    detector server in real time during readout)
    2) simple_horizontal	take the median of the 8 ref pix for each row,
    						and subtract that from each row.
    3) smoothed_horizontal	Like the above, but smoothed by N pixels vertically
							for better S/N. N is adjustable using the smoothing_size
							parameter. Empirically values < 20 or 30 seem to be
							not enough smoothing, so the read noise fluctuations
							give spurious biases to the ref pix model.
    3) interpolated		In this case, use James Larkin's interpolation
    						algorithm to remove linear variation with time
    						in the horizontal direction. This gives the highest
    						spatial frequency correction but is more affected
    						by read noise.

 	See discussion in section 3.1 of Rauscher et al. 2008 Prof SPIE 7021 p 63.





 ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.


 HISTORY:
 	Originally by Jerome Maire 2008-06
 	2009-04-20 MDP: Updated to pipeline format, added docs.
 				    Some code lifted from OSIRIS subtradark_000.pro
   2009-09-17 JM: added DRF parameters
   2012-07-27 MP: Added Method parameter, James Larkin's improved algorithm
   2012-10-14 MP: debugging and code cleanup.
   2013-07-17 MP: Rename for consistency
   2013-12-03 MP: Some docs updates and added SMOOTHED_HORIZONTAL algorithm and smoothing_size parameter

**Parameters**:

==================  ======  ====================================================================  ==============  ===================================================================
              Name    Type                                                                 Range         Default                                                          Description
==================  ======  ====================================================================  ==============  ===================================================================
              Save     int                                                                 [0,1]               0                                1: save output on disk, 0: don't save
             gpitv     int                                                               [0,500]               0    1-500: choose gpitv session for displaying output, 0: no display 
    smoothing_size     int                                                               [0,500]              31              Smoothing kernel size for smoothed_horizontal method.  
  before_and_after     int                                                                 [0,1]               0                Show the before-and-after images for the user to see?
            Method    enum    SIMPLE_CHANNELS|SIMPLE_HORIZONTAL|SMOOTHED_HORIZONTAL|INTERPOLATED    INTERPOLATED                           Algorithm for reference pixel subtraction.
==================  ======  ====================================================================  ==============  ===================================================================


**IDL Filename**: gpi_apply_reference_pixel_correction.pro


.. index::
    single:Update Spot Shifts for Flexure

.. _UpdateSpotShiftsforFlexure:

Update Spot Shifts for Flexure
------------------------------

 Extract a 3D datacube from a 2D image. Spatial integration (3 pixels) along the dispersion axis

**Category**:  SpectralScience, Calibration, PolarimetricScience      **Order**: 1.34

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
   2013-07-17 MP: Rename for consistency
   2013-12-02 JM: new way of dealing with the lookup table for flexure effect correction, independent of the reference wavelength solution used to calculate the shifts

**Parameters**:

===========  ========  ===========================  =========  ============================================================================================
       Name      Type                        Range    Default                                                                                   Description
===========  ========  ===========================  =========  ============================================================================================
     method    string    [None|Manual|Lookup|Auto]       None                          How to correct spot shifts due to flexure? [None|Manual|Lookup|Auto]
  manual_dx     float                     [-10,10]          0                        If method=Manual, the X shift of spectra at the center of the detector
  manual_dy     float                     [-10,10]          0                        If method=Manual, the Y shift of spectra at the center of the detector
    Display       int                     [-1,100]         -1    -1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot.
       Save       int                        [0,1]          0                                                         1: save output on disk, 0: don't save
      gpitv       int                      [0,500]          0                             1-500: choose gpitv session for displaying output, 0: no display 
===========  ========  ===========================  =========  ============================================================================================


**IDL Filename**: gpi_update_spot_shifts_for_flexure.pro


.. index::
    single:Destripe science image

.. _Destripescienceimage:

Destripe science image
----------------------

  Subtract detector striping using measurements between the microspectra

**Category**:  SpectralScience,Calibration, PolarimetricScience      **Order**: 1.35

**Inputs**: Not specified

**Outputs**: Not specified      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl



 This primitive was originally developed to remove striping and microphonics
 noise in IFS images. The noise level of the detector has since decreased
 significantly and therefore this primitive is generally only useful for
 short exposures. Note that without proper examination, this primitive may
 INTRODUCE a systematic noise into the image. Users should consult the
 IFS handbook destriping section when using this primitive.


  This primitive subtracts horizontal striping from the background of a 2d raw IFS image
  by masking spectra and using the remaining regions to obtain a
  sampling of the striping.

  The masking can be performed by using the wavelength calibration to mask the
  spectra (recommended) or by thresholding (not recommended).

  WARNING: This destriping algorithm will not work correctly on flat fields or
  any image where there is very large amounts of signal covering the entire
  field. If called on such data, it will print a warning message and return
  without modifying the data array.

  Summary of the primitive:
  The principle idea is to build models of the different source of noise
  you want to treat and then subtract them from the real image at the end.
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
  If Plot_micro_peaks equal 'yes', then it will open 3 plot windows with the peaks aera of the
  microphonics in Fourier space (Before microphonics subtraction, the
  microphonics to be removed and the final result). Used for debugging purposes.

  If remove_microphonics = 1:
    The algorithm is always applied.

  If remove_microphonics = 2:
    The algorithm is applied only of the quantity of noise is greater than the micro_threshold parameter.
    A default empirical value of 0.01 has been set based on the experience of the author of the algorithm.
    The quantity of microphonics noise is measured with the ratio of the dot_product and the norm of the
    image: dot_product/sqrt(sum(abs(fft(image))^2)).
    With dot_product = sum(abs(fft(image))*abs(fft(noise_model))) which
    correspond to the projection of the image on the microphonics noise model in the absolute Fourier space.

  There are 3 implemented methods right now depending on the value of the parameter method_microphonics.

  If method_microphonics = 1:
    The microphonics noise removal is based on a fixed precomputed model. This model is the
    normalized absolute value of the Fourier coefficients.
    The filtering consist of diminishing the intensity of the frequencies corresponding to the
    noise in the image proportionaly to the dot product of the image witht the noise model.
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

 Currently, the readnoise floor, which is what is used to determine the pixel masking for spectral mode, is set to 8 electrons divided by the
 square root of hte number of coadds. Note that for K band (and sometimes H) this often has to be adjusted. The channel
 offset correction should also be used when this value is being adjusted. Note that if too much of the image is masked,
 it will surpass the abort_fraction and no destriping will occur. Using an abort_fraction of 0.7 is the minimum
 a user should use for normal cases.




 HISTORY:
     Originally by Marshall Perrin, 2011-07-15
   2011-07-30 MP: Updated for multi-extension FITS
   2012-12-12 PI: Moved from Subtract_2d_background.pro
   2012-12-30 MMB: Updated for pol extraction. Included Cal file, inserted IDL version checking for smooth() function
   2013-01-16 MP: Documentation cleanup.
   2013-03-12 MP: Code cleanup, some speed enhancements by vectorization
   2013-05-28 JBR: Primitive copy pasted from the destripe_mask_spectra.pro primitive. Microphonics noise enhancement. Microphonics algorithm now applied before the destriping.
   2013-12-04 PI: Removed high_limit- now does masking based on readnoise levels
	2013-12-30 MP: CalibrationFile argument syntax update.
	2014-02-25 MP: flats in polarization mode are OK to destripe

**Parameters**:

=========================  ========  ======================  ===========  ================================================================================================================================================================================
                     Name      Type                   Range      Default                                                                                                                                                                       Description
=========================  ========  ======================  ===========  ================================================================================================================================================================================
                   method    string    [threshhold|calfile]      calfile                                                                                  Find background based on image value threshhold cut, or calibration file spectra/spot locations?
           abort_fraction     float               [0.0,1.0]          0.9                                                                                  Necessary fraction of pixels in mask to continue - set at 0.9 to ensure quicklook tool is robust
   chan_offset_correction       int                   [0,1]            0                                                                                                      Tries to correct for channel bias offsets - useful when no dark is available
          readnoise_floor     float               [0.0,100]          0.0                                                                                                                  Readnoise floor in ADU. 0 = default to 8 electrons per CDS image
             Save_stripes       int                   [0,1]            0                                                                                                                              Save the striping noise image subtracted from frame?
                  Display       int                [-1,100]           -1                                                                                         -1 = No display; 0 = New (unused) window else = Window number to display diagonostics in.
      remove_microphonics       int                   [0,2]            0    Remove microphonics noise based on a precomputed fixed model.0: not applied. 1: applied. 2: the algoritm is applied only if the measured noise is greater than micro_threshold
      method_microphonics       int                   [1,3]            0                                                                                               Method applied for microphonics 1: model projection. 2: all to zero 3: gaussian fit
          CalibrationFile    string                    None    AUTOMATIC                                                                                                                        Filename of the desired microphonics model file to be read
         Plot_micro_peaks    string                [yes|no]           no                                                                                                                            Plot in 3d the peaks corresponding to the microphonics
        save_microphonics    string                [yes|no]           no                                                                                If remove_microphonics = 1 or (auto and micro_threshold overpassed), save the removed microphonics
          micro_threshold     float               [0.0,1.0]         0.01                                                        If remove_microphonics = 2, set the threshold. This value is sum(abs(fft(image))*abs(fft(noise_model)))/sqrt(sum(image^2))
               write_mask       int                   [0,1]            0                                                                                                                                           write signal mask to reduced directory?
                 fraction     float               [0.0,1.0]          0.7                                                                                                                  Threshold fraction of the total pixels in a row should be masked
                     Save       int                   [0,1]            0                                                                                                                                             1: Save output to disk, 0: Don't save
                    gpitv       int                 [0,500]            1                                                                                                                 1-500: choose gpitv session for displaying output, 0: no display 
=========================  ========  ======================  ===========  ================================================================================================================================================================================


**IDL Filename**: gpi_destripe_science_image.pro


.. index::
    single:Destripe for Darks Only

.. _DestripeforDarksOnly:

Destripe for Darks Only
-----------------------

 Subtract readout pickup noise using median across all channels. This is an aggressive destriping algorithm suitable only for use on images that have no light. Also includes microphonics noise removal.

**Category**:  Calibration      **Order**: 1.35

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

=====================  ========  ==========  =========  ===========================================================================================
                 Name      Type       Range    Default                                                                                  Description
=====================  ========  ==========  =========  ===========================================================================================
  remove_microphonics    string    [yes|no]        yes                                  Attempt to remove microphonics noise via Fourier filtering?
              Display       int    [-1,100]         -1    -1 = No display; 0 = New (unused) window else = Window number to display diagonostics in.
                 Save       int       [0,1]          0                                                        1: save output on disk, 0: don't save
                gpitv       int     [0,500]          0                            1-500: choose gpitv session for displaying output, 0: no display 
=====================  ========  ==========  =========  ===========================================================================================


**IDL Filename**: gpi_destripe_for_darks_only.pro


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
	2013-07-12 MP: Rename file for consistency
	2013-12-16 MP: Update to allow bad pixel map files to have values other than
					1, with any nonzero value being interpreted as bad.
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

=====================  ========  =====================  ==========  ================================================================================================================
                 Name      Type                  Range     Default                                                                                                       Description
=====================  ========  =====================  ==========  ================================================================================================================
      CalibrationFile      None                   None        None                                                                 Filename of the desired bad pixel file to be read
               method    string    [n4n|vertical|all8]    vertical    Repair bad bix interpolating all 8 neighboring pixels, or just the 2 vertical ones, or just flag as NaN (n4n)?
                 Save       int                  [0,1]           0                                                                             1: save output on disk, 0: don't save
                gpitv       int                [0,500]           1                                                 1-500: choose gpitv session for displaying output, 0: no display 
  negative_bad_thresh     float            [-100000,0]         -50                                                         Pixels more negative than this should be considered bad. 
     before_and_after       int                  [0,1]           0                                     Show the before-and-after images for the user to see? (for debugging/testing)
=====================  ========  =====================  ==========  ================================================================================================================


**IDL Filename**: gpi_interpolate_bad_pixels_in_2d_frame.pro


.. index::
    single:Combine 2D images

.. _Combine2Dimages:

Combine 2D images
-----------------

 Combine 2D images such as darks into a master file via mean or median. 

**Category**:  ALL      **Order**: 1.5

**Inputs**:  Multiple 2D images

**Outputs**:  a single combined 2D image      **Output Suffix**:  strlowcase(method)

**Notes**:

.. code-block:: idl


  Multiple 2D images can be combined into one using either a mean,
  a sigma-clipped mean,  or a median.




 HISTORY:
 	 Jerome Maire 2008-10
   2009-09-17 JM: added DRF parameters
   2009-10-22 MDP: Created from mediancombine_darks, converted to use
   				accumulator.
   2010-01-25 MDP: Added support for multiple methods, MEAN method.
   2011-07-30 MP: Updated for multi-extension FITS
   2012-10-10 MP: Minor code cleanup
   2013-07-10 MP: Minor documentation cleanup
   2013-07-12 MP: file rename for consistency
   2014-01-02 MP: Copied SIGMACLIP implementation from gpi_combine_2d_dark_images


**Parameters**:

===========  ========  =======================  ===========  ===============================================================================================================================================
       Name      Type                    Range      Default                                                                                                                                      Description
===========  ========  =======================  ===========  ===============================================================================================================================================
     Method    string    MEAN|MEDIAN|SIGMACLIP    SIGMACLIP                                                      How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN|SIGMACLIP]
  Sigma_cut     float                  [1,100]            3    If Method=SIGMACLIP, then data points more than this many standard deviations away from the median value of a given pixel will be discarded. 
       Save       int                    [0,1]            1                                                                                                            1: save output on disk, 0: don't save
      gpitv       int                  [0,500]            2                                                                                1-500: choose gpitv session for displaying output, 0: no display 
===========  ========  =======================  ===========  ===============================================================================================================================================


**IDL Filename**: gpi_combine_2d_images.pro


.. index::
    single:Combine 2D Thermal/Sky Backgrounds

.. _Combine2DThermal/SkyBackgrounds:

Combine 2D Thermal/Sky Backgrounds
----------------------------------

 Combine 2D images with measurement of thermal or sky background

**Category**:  Calibration      **Order**: 1.51

**Inputs**:  2D image(s) taken with lamps off.

**Outputs**:  thermal background file, saved as calibration file      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	Generate a 2D background image for use in removing e.g. thermal emission
	from lamp images




 HISTORY:
   2012-12-13 MP: Forked from combine2dframes
   2013-07-10 MP: Minor documentation cleanup
   2013-07-12 MP: Rename for consistency
	2014-01-02 MP: Copied SIGMACLIP implementation from gpi_combine_2d_dark_images

**Parameters**:

===========  =======  =======================  ===========  ===============================================================================================================================================
       Name     Type                    Range      Default                                                                                                                                      Description
===========  =======  =======================  ===========  ===============================================================================================================================================
     Method     enum    MEAN|MEDIAN|SIGMACLIP    SIGMACLIP                                                      How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN|SIGMACLIP]
  Sigma_cut    float                  [1,100]            3    If Method=SIGMACLIP, then data points more than this many standard deviations away from the median value of a given pixel will be discarded. 
       Save      int                    [0,1]            1                                                                                                            1: save output on disk, 0: don't save
      gpitv      int                  [0,500]            2                                                                                1-500: choose gpitv session for displaying output, 0: no display 
===========  =======  =======================  ===========  ===============================================================================================================================================


**IDL Filename**: gpi_combine_2d_thermal_sky_backgrounds.pro


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


	This primitive positions of spectra in the image with narrow
	band lamp image.

	** DEPRECATED** This is the older 'first generation' wavelength
	calibration algorith, which is no longer recommended

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
   2012-12-20 JM: more centroid methods added
   2013-07-12 MP: Rename for consistency

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


**IDL Filename**: gpi_measure_wavelength_calibration.pro


.. index::
    single:2D Wavelength Solution

.. _2DWavelengthSolution:

2D Wavelength Solution
----------------------

 This primitive uses an existing wavelength solution file to construct a new wavelength solution file by simulating the detector image and performing a least squares fit.

**Category**:  Calibration      **Order**: 1.7

**Inputs**:  An Xe/Ar lamp detector image

**Outputs**:  A wavelength solution cube (and a simulated Xe/Ar lamp detector image; to come)      **Output Suffix**: 'wavecal'

**Notes**:

.. code-block:: idl


	This is the main wavelength calibration generation primitive.

   This Wavelength Solution generator models an arclamp spectrum
   for each lenslet and uses mpfit2dfunc to fit the relevant
   wavelength solution variables (ie. xo, yo, lambdao, dispersion,
   tilt). A wavelength solution file is output along with a
   simulated detector image.

	A previous wavelength calibration file is used to supply the
	initial guess for the fitting process, which is then updated
	by this primitive.

	This is fairly computationally intensive and requires
	relatively high S/N data. See Quick Wavelength Solution if
	you need faster results (albeit more limited and requiring you
	already have a reference wavecal)








 HISTORY:
    2013-09-19 SW: 2-dimensionsal wavelength solution

**Parameters**:

===================  ========  =========  ===========  =============================================================================================================================
               Name      Type      Range      Default                                                                                                                    Description
===================  ========  =========  ===========  =============================================================================================================================
            display       Int      [0,1]            0    Whether or not to plot each lenslet spectrum model in comparison to the detector measured spectrum: 1;display, 0;no display
           whichpsf       Int      [0,1]            0                                                                           Type of lenslet PSF model, 0: gaussian, 1: microlens
           parallel       Int      [0,1]            0                                                                              Option for Parallelization,  0: none, 1: parallel
           numsplit       Int    [0,100]            0                                                                  Number of cores for parallelization. Set to 0 for autoselect.
               Save       int      [0,1]            1                                                                                          1: save output on disk, 0: don't save
             Smooth       int      [0,1]            1                                                              1: Smooth over poorly fit lenslets in final datacube; 0:NO, 1:YES
   Save_model_image       int      [0,1]            0                                                                      1: save 2d detector model fit image to disk, 0:don't save
    CalibrationFile    wavcal       None    AUTOMATIC                                                       Filename of the desired reference wavelength calibration file to be read
  Save_model_params       int      [0,1]            0                                                                       1: save model nuisance parameters to disk, 0: don't save
         AutoOffset       int      [0,1]            0                                                                           Automatically determine x/yoffset values 0;NO, 1;YES
===================  ========  =========  ===========  =============================================================================================================================


**IDL Filename**: gpi_wavelength_solution_2d.pro


.. index::
    single:Quick Wavelength Solution Update

.. _QuickWavelengthSolutionUpdate:

Quick Wavelength Solution Update
--------------------------------

 Given an existing wavecal and a new Xe lamp image, this primitive updates the wavecal based on the X,Y positions measured for a subset of the Xe spectra. 

**Category**:  Calibration      **Order**: 1.7

**Inputs**:  An Xe/Ar lamp detector image

**Outputs**: Not specified      **Output Suffix**: 'wavecal'

**Notes**:

.. code-block:: idl


   This is a modified version of the 2D wavelength solution
   algorithm, which fits a small subset of lenslets (set by
   the 'spacing' argument) to very quickly provide an estimated
   wavelength solution, based on some prior wavelength solution.

   This differs from the full wavelength solution in that:

    1) Only a subset of lenslets are fit
    2) The mean shifts in X and Y are derived from those fits
    3) The output wavelength solution is created by taking
       the input wavelength solution and applying those shifts.
       (i.e. only the overall shift of the wavecal is updated;
       the individual dispersions and tilts of each lenslet's
       spectrum are not changed).

   This algorithm is both computationally faster than and
   tolerant of lower S/N data than the full wavelength solution
   algorithm. This is because it is in essence only trying to measure
   2 parameters, the average shifts in X and Y, rather than the
   ~ 150,000 parameters measured and saved for the full wavelength
   calibration algorithm.


 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER,IFSFILT,GCALLAMP
 DRP KEYWORDS: FILETYPE,HISTORY,ISCALIB





 HISTORY:
	2013-09-19 SW: 2-dimensionsal wavelength solution
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

==================  ========  ==========  ===========  ==================================================================================================================================
              Name      Type       Range      Default                                                                                                                         Description
==================  ========  ==========  ===========  ==================================================================================================================================
           Display       int    [-1,100]           -1    -1 = No display; 0 = New (unused) window; else = Window number to display each lenslet in comparison to the detector lenslet in.
           spacing       Int      [0,20]           10                                                                                         Test every Nth lenslet for this value of N.
          boxsizex       Int      [0,15]            7                                                                                                     x dimension of a lenslet cutout
          boxsizey       Int      [0,50]           24                                                                                                     y dimension of a lenslet cutout
           xoffset       Int    [-10,10]            0                                                                                                  x offset guess from prior wavecal.
           yoffset       Int    [-20,20]            0                                                                                                  y offset guess from prior wavecal.
          whichpsf       Int       [0,1]            0                                                                                                 Type of psf 0;gaussian, 1;microlens
   CalibrationFile    String        None    AUTOMATIC                                                                      Filename of the desired wavelength calibration file to be read
              Save       int       [0,1]            1                                                                                               1: save output on disk, 0: don't save
        AutoOffset       int       [0,1]            0                                                                                Automatically determine x/yoffset values 0;NO, 1;YES
  gpitvim_dispgrid       int     [0,500]           15                                 1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display 
==================  ========  ==========  ===========  ==================================================================================================================================


**IDL Filename**: gpi_quick_wavelength_solution_update.pro


.. index::
    single:Measure Polarization Spot Calibration

.. _MeasurePolarizationSpotCalibration:

Measure Polarization Spot Calibration
-------------------------------------

 Derive polarization calibration files from a flat field image.

**Category**:  Calibration      **Order**: 1.8

**Inputs**:  2D image from flat field  in polarization mode

**Outputs**:  Measured polarization spot locations calibration file      **Output Suffix**: Could not be determined automatically

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




 HISTORY:
   2009-06-17: Started, based on gpi_extract_wavcal - Marshall Perrin
   2009-09-17 JM: added DRF parameters
   2013-01-28 MMB: added some keywords to pass to find_pol_positions_quadrant
   2013-07-11 MDP: Documentation cleanup.
   2013-07-12 MDP: Rename for consistency

**Parameters**:

===========  =======  ============  =========  ================================================================================
       Name     Type         Range    Default                                                                       Description
===========  =======  ============  =========  ================================================================================
      nlens      int       [0,400]        281                                               side length of  the  lenslet array 
  centrXpos      int      [0,2048]       1078              Initial approximate x-position [pixel] of central peak at 1.5microns
  centrYpos      int      [0,2048]       1028              Initial approximate y-position [pixel] of central peak at 1.5microns
          w    float      [0.,10.]        4.4    Spectral spacing perpendicular to the dispersion axis at the detcetor in pixel
          P    float      [-7.,7.]       2.18                                                               Micro-pupil pattern
     maxpos    float      [-7.,7.]        2.5            Allowed maximum location fluctuation (in pixel) between adjacent mlens
   FitWidth    float    [-10.,10.]          3                                     Size of box around a spot used to find center
       Save      int         [0,1]          1                                                                              None
    Display      int         [0,1]          1                                                                              None
===========  =======  ============  =========  ================================================================================


**IDL Filename**: gpi_measure_polarization_spot_calibration.pro


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

**Inputs**:  detector image in polarimetry mode

**Outputs**:  Polarization pair datacube      **Output Suffix**: '-podc'

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



 HISTORY:
   2009-04-22 MDP: Created, based on DST's cubeextract_polarized.
   2009-09-17 JM: added DRF parameters
   2009-10-08 JM: add gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-15 MP: Code cleanup.
   2011-06-07 JM: added FITS/MEF compatibility
   2013-01-02 MP: Updated output file orientation to be consistent with
				   spectral mode and raw data.
	2013-07-17 MP: Renamed for consistency
   2013-11-30 MP: Clear DQ and Uncert pointers
   2014-02-03 MP: Code and docs cleanup

**Parameters**:

========  ========  =========  =========  ===================================================================
    Name      Type      Range    Default                                                          Description
========  ========  =========  =========  ===================================================================
    Save       int      [0,1]          0                                1: save output on disk, 0: don't save
   gpitv       int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
  Method    String    BOX|PSF        BOX        Method for pol cube reconstruction, simple box or optimal PSF
========  ========  =========  =========  ===================================================================


**IDL Filename**: gpi_assemble_polarization_cube.pro


.. index::
    single:Assemble Spectral Datacube

.. _AssembleSpectralDatacube:

Assemble Spectral Datacube
--------------------------

 Assemble a 3D datacube from a 2D image. Spatial integration (3 pixels box) along the dispersion axis

**Category**:  SpectralScience, Calibration      **Order**: 2.0

**Inputs**: Not specified

**Outputs**: Not specified      **Output Suffix**: '-rawspdc'

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
   2013-04-02 JBR: Correction on the y coordinate when reading the det array to match centered pixel convention. Removal of the reference pixel area.
   2013-07-17 MDP: Rename for consistency
   2013-08-06 MDP: Documentation update, code cleanup to relabel X and Y properly
   2013-11-30 MDP: Clear DQ and Uncert pointers

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          0                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_assemble_spectral_datacube.pro


.. index::
    single:Assemble Undispersed Image

.. _AssembleUndispersedImage:

Assemble Undispersed Image
--------------------------

 Extract a 2D image from a raw undispersed mode image. Box integration of the light from each lenslet.

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
   2013-07-17 MP: Rename for consistency
   2013-11-30 MDP: Clear DQ and Uncert pointers

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


**IDL Filename**: gpi_assemble_undispersed_image.pro


.. index::
    single:Noise and Flux Analysis

.. _NoiseandFluxAnalysis:

Noise and Flux Analysis
-----------------------

 Store a few key values as fits keywords in the file. It can generate anciliary files too.

**Category**:  HIDDEN      **Order**: 2.1

**Inputs**: Not specified

**Outputs**:  Changes is the header of the file without changing the data and saving a fits file report with the value of the sliding median/standard deviation computation.      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


   /!\ HIDDEN /!\ It was a primitive used by JB for debug but I don't think it is gonna be used by anyone else.

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


**IDL Filename**: gpi_noise_and_flux_analysis.pro


.. index::
    single:Divide by Lenslet Flat Field

.. _DividebyLensletFlatField:

Divide by Lenslet Flat Field
----------------------------

 Divides a spectral data-cube by a flat field data-cube.

**Category**:  SpectralScience,PolarimetricScience,Calibration      **Order**: 2.2

**Inputs**:  Spectral or polarization datacube

**Outputs**:  Each slice of the input datacube is divided by the lenslet flat.

**Notes**:

.. code-block:: idl





 HISTORY:
   2014-01-02 MP: New primitive

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    string       None    AUTOMATIC       Filename of the desired wavelength calibration file to be read
             Save       int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: gpi_divide_by_lenslet_flat_field.pro


.. index::
    single:Divide by Spectral Flat Field

.. _DividebySpectralFlatField:

Divide by Spectral Flat Field
-----------------------------

 Divides a spectral data-cube by a flat field data-cube.

**Category**:  SpectralScience,Calibration      **Order**: 2.2

**Inputs**:  data-cube

**Outputs**:  Flat fielded datacube

**Notes**:

.. code-block:: idl


   ** Needs additional work, will not produce high qualty results yet **



 HISTORY:
   2009-08-27: JM created
   2009-09-17 JM: added DRF parameters
   2009-10-09 JM added gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07 JM: added check for NAN & zero
   2012-10-11 MP: Added min/max wavelength checks
   2012-10-17 MP: Removed deprecated suffix= keyword
   2013-07-17 MP: Rename for consistency
	2013-12-30 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    string       None    AUTOMATIC       Filename of the desired wavelength calibration file to be read
             Save       int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: gpi_divide_by_spectral_flat_field.pro


.. index::
    single:Remove Flat Lamp spectrum

.. _RemoveFlatLampspectrum:

Remove Flat Lamp spectrum
-------------------------

 Fit the lamp spectrum and remove it (for delivering flat field cubes)

**Category**:  Calibration      **Order**: 2.25

**Inputs**:  Flat field data-cube

**Outputs**:   Flat datacube normalized to remove lamp spectrum      **Output Suffix**: 'specflat'

**Notes**:

.. code-block:: idl


           Rescale flat-field (keep large scale variations)

           **CAUTION needs additional improvement **





 GEM/GPI KEYWORDS:
 DRP KEYWORDS: FILETYPE, ISCALIB



 HISTORY:
 	2009-06-20 JM: created
 	2009-07-22 MP: added doc header keywords
 	2012-10-11 MP: added min/max wavelength checks
 	2013-07-17 MP: Rename for consistency
   2013-12-03 MP: Add check for GCALLAMP=QH on input images

**Parameters**:

========  ========  ===============================  ===========  ===================================================================
    Name      Type                            Range      Default                                                          Description
========  ========  ===============================  ===========  ===================================================================
    Save       int                            [0,1]            1                                1: save output on disk, 0: don't save
   gpitv       int                          [0,500]            2    1-500: choose gpitv session for displaying output, 0: no display 
  method    string    polyfit|linfit|blackbody|none    blackbody                             Method to use for removing lamp spectrum
========  ========  ===============================  ===========  ===================================================================


**IDL Filename**: gpi_remove_flat_lamp_spectrum.pro


.. index::
    single:Interpolate Wavelength Axis

.. _InterpolateWavelengthAxis:

Interpolate Wavelength Axis
---------------------------

 Interpolate spectral datacube onto regular wavelength sampling.

**Category**:  SpectralScience,Calibration      **Order**: 2.3

**Inputs**:   A raw irregularly-sampled spectral datacube

**Outputs**:  Spectral datacube with slices at a regular wavelength sampling      **Output Suffix**: 'spdc'

**Notes**:

.. code-block:: idl


		Interpolate datacube to have each slice at the same wavelength.
		This is a necessary step of creating datacubes in spectral mode
		and should always be used right after Assemble Spectral Datacube.

		Also adds wavelength keywords to the FITS header.



 HISTORY:
 	Originally by Jerome Maire 2008-06
 	2009-04-15 MDP: Documentation improved.
   2009-06-20 JM: adapted to wavcal
   2009-09-17 JM: added DRF parameters
   2010-03-15 JM: added error handling
   2012-12-09 MP: Updates to WCS output
   2013-07-12 MP: Rename for consistency

**Parameters**:

==================  ======  =========  =========  ===================================================================
              Name    Type      Range    Default                                                          Description
==================  ======  =========  =========  ===================================================================
  Spectralchannels     int    [0,100]         37                Choose how many spectral channels for output datacube
              Save     int      [0,1]          1                                1: save output on disk, 0: don't save
             gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
==================  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_interpolate_wavelength_axis.pro


.. index::
    single:Subtract Thermal/Sky Background Cube if K band

.. _SubtractThermal/SkyBackgroundCubeifKband:

Subtract Thermal/Sky Background Cube if K band
----------------------------------------------

 Subtract a thermal/sky cube 

**Category**:  ALL      **Order**: 2.35

**Inputs**:  3D image file

**Outputs**:  3D image file, unchanged if YJH, background subtracted if K1 or K2.      **Output Suffix**:  'bkgnd_cube_sub'

**Notes**:

.. code-block:: idl


  Subtract thermal background emission in the datacube, for K band data only

  This is identical to the gpi_subtact_thermal_sky_if_k_band primtive except the subtraction
  is done in cube space instead of detector space. It also uses sky cubes rather than the 2d sky images.

	** special note: **

	This is a new kind of "data dependent optional primitive". If the filter of
	the current data is YJH, return without doing *anything*, even logging the
	start/end of this primitive.  It becomes a complete no-op for non-K-band
	cases.

 Algorithm:

	Get the best available thermal/sky background cube calibration file from CalDB
	Scale it to current exposure time
	Subtract it.
   The name of the calibration file used is saved to the DRPBKGND header keyword.

 ALGORITHM TODO: Deal with uncertainty and pixel mask frames too.





 HISTORY:
   2013-12-23 PI: Initial implementation

**Parameters**:

==================  ========  =========  ===========  =================================================================================================================
              Name      Type      Range      Default                                                                                                        Description
==================  ========  =========  ===========  =================================================================================================================
   CalibrationFile    string       None    AUTOMATIC                                                                    Name of thermal/sky background cube to subtract
              Save       int      [0,1]            0                                                                              1: save output on disk, 0: don't save
  Override_scaling     float     [0,10]          1.0    Set to value other than 1 to manually adjust the background image flux scaling to better match the science data
             gpitv       int    [0,500]            0                                                  1-500: choose gpitv session for displaying output, 0: no display 
==================  ========  =========  ===========  =================================================================================================================


**IDL Filename**: gpi_subtract_thermal_sky_background_cube_if_k_band.pro


.. index::
    single:Check for closed-loop coronagraphic image

.. _Checkforclosed-loopcoronagraphicimage:

Check for closed-loop coronagraphic image
-----------------------------------------

  Check whether file represents a closed-loop  coronagraphic image.

**Category**:  Calibration,SpectralScience,PolarimetricScience      **Order**: 2.41

**Inputs**: Not specified

**Outputs**: Not specified

**Notes**:

.. code-block:: idl


	This primitive checks that the input file is in fact a coronagraphic image.
	It is intended to be used in quicklook recipes that may encounter all sorts
	of different data.

	Any following primitives will only be executed if the
	image is in fact coronagraphic data. This is useful so the quicklook
	recipe can include satellite spots or contrast measurement primitives,
	which would generally cause the recipe to fail if they receive any
	unocculted data. With this primitive added in the recipe before those
	steps, they will just be skipped without producing any error messages.



 HISTORY:
   2013-08-02 ds - initial version
   2013-11-12 MP - add check for PUPVIEWR inserted

**Parameters**:

==============  ======  =======  =========  ======================================================
          Name    Type    Range    Default                                             Description
==============  ======  =======  =========  ======================================================
  err_on_false     int    [0,1]          0     If false, 0: continue to next image; 1: Throw error
==============  ======  =======  =========  ======================================================


**IDL Filename**: gpi_check_coronagraph_status.pro


.. index::
    single:Correct Distortion

.. _CorrectDistortion:

Correct Distortion
------------------

 Correct GPI distortion

**Category**:  SpectralScience,PolarimetricScience      **Order**: 2.44

**Inputs**:  spectral or polarimetric datacube

**Outputs**:   Distortion-corrected datacube      **Output Suffix**: '_distorcorr'

**Notes**:

.. code-block:: idl


	Corrects distortion by bilinear resampling of the
	input datacube according to a predetermined distortion solution.






 HISTORY:
 	Originally by Jerome Maire 2009-12
   2013-04-23 Major change of the code, now based on Quinn's routine for distortion correction - JM
   2013-07-16 MP: Rename for consistency
	2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
             Save       int      [0,1]            1                                1: save output on disk, 0: don't save
  CalibrationFile    string       None    AUTOMATIC       Filename of the desired distortion calibration file to be read
            gpitv       int    [0,500]           10    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: gpi_correct_distortion.pro


.. index::
    single:Measure GPI distortion from grid pattern

.. _MeasureGPIdistortionfromgridpattern:

Measure GPI distortion from grid pattern
----------------------------------------

 Measure GPI distortion from grid pattern

**Category**:  Calibration HIDDEN      **Order**: 2.44

**Inputs**:  Not used

**Outputs**:  Distortion correction coefficients file (values are currently hard-coded)      **Output Suffix**: '-distor'

**Notes**:

.. code-block:: idl


	CAUTION - NOT IMPLEMENTED

	the distortion in lab was analyzed with other non-pipeline tools by Quinn,
	and the result is just hard coded here to output it in the GPI pipeline
	format.





 HISTORY:
 	Originally by Jerome Maire 2009-12
       Switched sxaddpar to backbone->set_keyword 01.31.2012 Dmitry Savransky
   2013  Added hard-coded measurement of the distortion made by Quinn   JM

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

 Measure the locations of the satellite spots in the datacube, and save the results to the FITS keyword headers.

**Category**:  Calibration,SpectralScience      **Order**: 2.44

**Inputs**: Not specified

**Outputs**: Not specified

**Notes**:

.. code-block:: idl


  Measures the locations of the satellite spots; saves to FITS keywords.
  The sat spots locations are saved to SATS1_1, SATS1_2, and so on.
  The inferred location of the star is saved to PSFCENTX and PSFCENTY
  (this is the mean location of all the locations at each wavelength)


 HISTORY:
 	Originally by Jerome Maire 2009-12
   2012-09-18 Offloaded functionality to common backend - ds
   2013-07-17 MP Documentation updated, rename for consistency.

**Parameters**:

=================  ======  =========  =========  ====================================================================================================================================
             Name    Type      Range    Default                                                                                                                           Description
=================  ======  =========  =========  ====================================================================================================================================
      refine_fits     int      [0,1]          1                                                                                     0: Use wavelength scaling only; 1: Fit each slice
  reference_index     int    [-1,50]         -1                                                                   Index of slice to use for initial satellite detection. -1 for Auto.
    search_window     int     [1,50]         20                                                                                 Radius of aperture used for locating satellite spots.
         highpass     int     [0,25]          1                                                       1: Use high pass filter (default size) 0: don't 2+: size of highpass filter box
        constrain     int      [0,1]          0                                                             1: Constrain distance between sat spots by band; 0: Unconstrained search.
             Save     int      [0,1]          0                                                                                                 1: save output on disk, 0: don't save
        loc_input     int      [0,2]          0                                                   0: Find spots automatically; 1: Use values below as initial satellite spot location
               x1     int    [0,300]          0        approx x-location of top left spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y1     int    [0,300]          0        approx y-location of top left spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               x2     int    [0,300]          0     approx x-location of bottom left spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y2     int    [0,300]          0     approx y-location of bottom left spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               x3     int    [0,300]          0       approx x-location of top right spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y3     int    [0,300]          0       approx y-location of top right spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               x4     int    [0,300]          0    approx x-location of bottom right spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
               y4     int    [0,300]          0    approx y-location of bottom right spot on reference slice of the datacube in pixels (not considered if CalibrationFile is defined)
=================  ======  =========  =========  ====================================================================================================================================


**IDL Filename**: gpi_measure_satellite_spot_locations.pro


.. index::
    single:Measure Star Position for Polarimetry

.. _MeasureStarPositionforPolarimetry:

Measure Star Position for Polarimetry
-------------------------------------

 Finds the location of the occulted star in polarimetry mode, and save the results to the FITS keyword headers.

**Category**:  Calibration, PolarimetricScience      **Order**: 2.445

**Inputs**:  Polarimetric mode datacube

**Outputs**:  Polarimetric mode datacube with star location recorded in header

**Notes**:

.. code-block:: idl


  Finds the location of the occulted star (i.e. image center); saves center to FITS keywords.
  The algorithm used is a version of the radon transform, used to find where
  all the broadband extended speckles intersect in the image.

  The inferred star location is saved to PSFCENTX, PSFCENY keywords in the
  header





 HISTORY:
 	2014-01-31 JW: Created. Accurary is subpixel - hopefully.

**Parameters**:

=================  =======  ==================  =========  ===================================================================
             Name     Type               Range    Default                                                          Description
=================  =======  ==================  =========  ===================================================================
               x0      int             [0,300]        147                          initial guess for image center x-coordinate
               y0      int             [0,300]        147                           inital guess ofr image center y-coordinate
    search_window      int              [1,50]          5                     Radius of search window to search for the center
      mask_radius      int             [0,100]         50        Radius of center of image to mask (centered on x0, y0 inputs)
         highpass      int               [0,1]          1                                     1: Use high pass filter 0: don't
  lower_threshold    float    [-100000,100000]       -100                   Lower pixel values will be converted to this value
             Save      int               [0,1]          0                                1: save output on disk, 0: don't save
            gpitv      int             [0,500]          0    1-500: choose gpitv session for displaying output, 0: no display 
=================  =======  ==================  =========  ===================================================================


**IDL Filename**: gpi_measure_star_position_for_polarimetry.pro


.. index::
    single:Measure satellite spot peak fluxes

.. _Measuresatellitespotpeakfluxes:

Measure satellite spot peak fluxes
----------------------------------

 Calculate peak fluxes of satellite spots in datacubes 

**Category**:  Calibration,SpectralScience      **Order**: 2.45

**Inputs**:  spectral datacube with spot locations in the header

**Outputs**:   datacube with measured spot fluxes

**Notes**:

.. code-block:: idl


   Measure the fluxes of the satellite spots.
   You must run 'Measure Satellite Spot Locations' before you can use this
   one.

	Spot fluxes are measured and then saved to SATF1_1, SATF1_2 etc keywords
	in the header.





 HISTORY:
 	Written 09-18-2012 savransky1@llnl.gov
 	2013-07-17 MP: Renamed for consistency

**Parameters**:

=================  ======  ========  =========  ===================================================================
             Name    Type     Range    Default                                                          Description
=================  ======  ========  =========  ===================================================================
        gauss_fit     int     [0,1]          1    0: Extract maximum pixel; 1: Correlate with Gaussian to find peak
  reference_index     int    [0,50]          0               Index of slice to use for initial satellite detection.
           ap_rad     int    [1,50]          7                           Radius of aperture used for finding peaks.
             Save     int     [0,1]          0                                1: save output on disk, 0: don't save
=================  ======  ========  =========  ===================================================================


**IDL Filename**: gpi_measure_satellite_spot_peak_fluxes.pro


.. index::
    single:Interpolate bad pixels in cube

.. _Interpolatebadpixelsincube:

Interpolate bad pixels in cube
------------------------------

  Repair bad pixels by interpolating between their neighbors. 

**Category**:  SpectralScience, PolarimetricScience, Calibration      **Order**: 2.5

**Inputs**:  Cube in either spectral or polarization mode

**Outputs**:  Cube with bad pixels potentially found and cleaned up.      **Output Suffix**: '-bpfix'

**Notes**:

.. code-block:: idl


	Searches for statistical outlier bad pixels in a cube and replace them
	by interpolating between their neighbors.

  CAUTION:
	Heuristic and not guaranteed or tested in any way; this is more a
	convenience function than a rigorous statistcally justified repair tool





 HISTORY:
	2013-12-14 MP: Created as a convenience function cleanup tool. Almost
	certainly not the best algorithm - just something quick and good enough for
	now?

**Parameters**:

==================  ======  =========  =========  ===============================================================================
              Name    Type      Range    Default                                                                      Description
==================  ======  =========  =========  ===============================================================================
              Save     int      [0,1]          0                                            1: save output on disk, 0: don't save
             gpitv     int    [0,500]          1                1-500: choose gpitv session for displaying output, 0: no display 
  before_and_after     int      [0,1]          0    Show the before-and-after images for the user to see? (for debugging/testing)
==================  ======  =========  =========  ===============================================================================


**IDL Filename**: gpi_interpolate_bad_pixels_in_cube.pro


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
   2013-08-07 ds: idl2 compiler compatible

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

 Apply photometric calibration to a single or set of datacubes

**Category**:  SpectralScience      **Order**: 2.51

**Inputs**: 

**Outputs**: Not specified      **Output Suffix**: '-phot'

**Notes**:

.. code-block:: idl


	This primitive applies a spectrophotometric calibrations to the datacube that is determined either
	from the satellite spots of the supplied cube, the satellite spots of a
	user-indicated cube, or any user-supplied spectral response function (e.g. derived
	from an open loop image of a standard star).

 The user may also specify the extraction and sky radii used in performing the aperture photometry. Note that the 'annuli' only represent the radial size of the extraction. The background is extracted by fitting a constant to an annulus surrounding the central star at the same radius as the planet. The inner width of the annulus is equal to the inner_sky_radius, the outer annulus describes the distance from the companion to the edges of the annulus that should be considered when fitting the constant. If the user wishes to examine the section being fit, they should modify line 350 accordingly.

 Error bars are calculated and put into the headers to be used with future primitives such as gpi_extract_1d_spectrum. They are determined by convolving the sky annulus with the extraction aperture then taking the standard deviation.



	1: datacube that requires calibration (loaded as an Input FITS file)
	AND
	2a: datacube or to be used to determine the calibration (with or without a accompanying model spectrum of the star)
	OR
	2b: a 2D spectrum (in ADU per COADD, where the COADD corresponds to input #1). The file format must be three columns, the first being wavelength in microns, the second being the flux in erg/s/cm2/A, the third being the uncertainty

 if neither 2a nor 2b or defined, the satellites of the input file are used.

 calib_cube_name and calib_model_spectrum require the entire directory+filename unless they are in the output directory
 calib_spectrum requires the full filename


 GEM/GPI KEYWORDS:FILTER,IFSUNIT
 DRP KEYWORDS: CUNIT,DATAFILE



 HISTORY:

   JM 2010-03 : created module.
   2012-10-17 MP: Removed deprecated suffix keyword. needs major cleanup!
   2013-08-07 ds: idl2 compiler compatible
	2014-01-07 PI: Created new gpi_calibrate_photometric_flux - big overhaul from the original apply_photometric_calibration

**Parameters**:

======================  ========  ==========  =========  ==========================================================================================================
                  Name      Type       Range    Default                                                                                                 Description
======================  ========  ==========  =========  ==========================================================================================================
                  Save       int       [0,1]          0                                                                       1: save output on disk, 0: don't save
                 gpitv       int     [0,500]          0                                           1-500: choose gpitv session for displaying output, 0: no display 
     extraction_radius     float    [0,1000]         3.    Aperture radius at middle wavelength (in spaxels i.e. mlens) to extract photometry for each wavelength. 
      inner_sky_radius     float     [1,100]        10.     Inner aperture radius at middle wavelength (in spaxels i.e. mlens) to extract sky for each wavelength. 
      outer_sky_radius     float     [1,100]        15.     Outer aperture radius at middle wavelength (in spaxels i.e. mlens) to extract sky for each wavelength. 
          c_ap_scaling       int       [0,1]          1                                                                   Perform aperture scaling with wavelength?
       calib_cube_name    string        None                                    Leave blank to use satellites of this cube, or enter a file to use those satellites
  calib_model_spectrum    string        None                Leave blank to use satellites of this cube, or enter a file to use with the spectrum for the satellites
        calib_spectrum    string        None                                          Leave blank to use satellites of this cube, or enter calibrated spectrum file
            FinalUnits       int      [0,10]          1       0: ADU per coadd, 1: ADU/s, 2: ph/s/nm/m^2, 3: Jy, 4: 'W/m^2/um, 5: ergs/s/cm^2/A, 6: ergs/s/cm^2/Hz'
======================  ========  ==========  =========  ==========================================================================================================


**IDL Filename**: gpi_calibrate_photometric_flux.pro


.. index::
    single:Extract 1D spectrum from a datacube

.. _Extract1Dspectrumfromadatacube:

Extract 1D spectrum from a datacube
-----------------------------------

 Extract one spectrum from a datacube somewhere in the FOV specified by the user.

**Category**:  SpectralScience      **Order**: 2.52

**Inputs**:  Datacube containing a source that needs extracting, located by the xcenter and ycenter arguments

**Outputs**:  1D spectrum      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


 WARNING: This primitive will not provide spectra of publishable quality
 it is designed to perform a quick extraction of a source.


 This primitive extracts a spectrum from a data cube. It is meant to be used
 on datacubes that have been calibrated by gpi_apply_photometric_calibration,
 but this is not strictly required.

 The extraction radius is pulled out of the header such that is uses the
 same as what was used to calibrate the cube. If they keyword is not found,
 then the extraction_radius keyword is used. The extraction_radius keyword will
 also be used if the override keyword is set to 1. Note that this is NOT
 recommended and will introduce systematics into the data.

 The centroiding is performed by fitting a gaussian to the region of interest.
 A line is then fit to the centroids and used. In this fit, the first and last
 4 data points are excluded due to low transmission. The errors for each centroid
 are determined by taking the largest of the offsets between the subtraction of adjacent
 centroids (e.g. yerr[j]=0.1>abs(yarr0[j]-yarr0[j+1])>abs(yarr0[j]-yarr0[j-1]) )

 All photometry is done in ADU/coadd. This is performed by converting the cube to
 ADU/coadd then converting back to whatever units the cube was input with.

 The error bars are determined using the same method as the satellite spots
 in gpi_calibrate_photometric_flux primitive. The user specifies the sky radii used in performing the aperture photometry. Note that the 'annuli' only represent the radial size of the extraction. The background is extracted by fitting a constant to an annulus surrounding the central star at the same radius as the planet. The inner width of the annulus is equal to the inner_sky_radius, the outer annulus describes the distance from the companion to the edges of the annulus that should be considered when fitting the constant. If the user wishes to examine the section being fit, they should modify line 350 accordingly.

 Highpass filtering the image is recommended to determine the centroids, note that the highpass filtered image
 is not used when measuring the extracted spectrum.


 KEYWORDS:

 Save: Set to 1 to save the spectrum to a disk file (.fits).
 xcenter: x-location of extraction (in pixels)
 ycenter: y-location of extraction (in pixels)
 highpass: highpass filter the image when determining centroid?
 inner_sky_radius: inner radius used in defining sky subtraction annulus section
 outer_sky_radius: outer radius used in defining sky subtraction annulus section
 override: allows input of a new extraction radius, and the use/non-use of c_ap_scaling
 extraction_radius: Radius used to define annulus for source extraction. This keyword is only active if the override keyword is set, or if the CEXTR_AP keyword, set by the Calibrate Photometric Flux primitive (gpi_calibrate_photometric_flux.pro) is not present in the header
 c_ap_scaling: keyword that activates the scaling of the apertures with wavelength. This keyword is only active if the override keyword is set, or if the C_AP_SC keyword, set by the Calibrate Photometric Flux primitive (gpi_calibrate_photometric_flux.pro) is not present in the header
 display: window used to display the extracted spectrum plot
 save_ps_plot: saves a postscript version of the plot if desired
 write_ascii_file: writes as ascii output of the spectra - no header info included

 GEM/GPI KEYWORDS:FILTER,IFSUNIT
 DRP KEYWORDS: CUNIT,DATAFILE,SPECCENX,SPECCENY


 HISTORY:

   2014-01-07 PI: Created Module - big overhaul from the original extract 1d spectrum

**Parameters**:

======================  =======  ==========  =========  ==========================================================================================================================================
                  Name     Type       Range    Default                                                                                                                                 Description
======================  =======  ==========  =========  ==========================================================================================================================================
                  Save      int       [0,1]          1                                                                                                       1: save output on disk, 0: don't save
               xcenter    float    [-1,280]         -1                                                                              x-location in pixels on datacube where extraction will be made
               ycenter    float    [-1,280]         -1                                                                              y-location in pixels on datacube where extraction will be made
              highpass      int      [0,25]          0                                                                                                    highpass filter box size for centroiding
  no_centroid_override      int       [0,1]          0                                                                                                       Do not centroid on extraction source?
      inner_sky_radius    float     [1,100]        10.                                                     Inner aperture radius at middle wavelength slice (in spaxels i.e. mlens) to extract sky
      outer_sky_radius    float     [1,100]        20.                                                     Outer aperture radius at middle wavelength slice (in spaxels i.e. mlens) to extract sky
              override      int       [0,1]          0                                                                             Override apertures/scaling from spectrophotometric calibration?
     extraction_radius    float    [0,1000]         5.    Aperture radius at middle wavelength (in spaxels i.e. mlens) to extract photometry for each wavelength. (only active if Override is set)
          c_ap_scaling      int       [0,1]          1                                                                                                   Perform aperture scaling with wavelength?
               display      int    [-1,100]         17                                                  -1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot.
          save_ps_plot      int       [0,1]          0                                                                                                                    Save PostScript of plot?
      write_ascii_file      int       [0,1]          0                                                                                                         Save ascii file of spectrum (.dat)?
======================  =======  ==========  =========  ==========================================================================================================================================


**IDL Filename**: gpi_extract_1d_spectrum.pro


.. index::
    single:Calibrate astrometry from binary (using separation and PA)

.. _Calibrateastrometryfrombinary(usingseparationandPA):

Calibrate astrometry from binary (using separation and PA)
----------------------------------------------------------

 Calculate astrometry from unocculted binaries using user-specified separation and PA at DATEOBS

**Category**:  Calibration      **Order**: 2.6

**Inputs**:  data-cube

**Outputs**:   plate scale & orientation      **Output Suffix**: 'astrom' ; output suffix

**Notes**:

.. code-block:: idl



 GEM/GPI KEYWORDS:CRPA
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
 	Originally by Jerome Maire 2009-12
 	2013-07-19 MP: Rename for consistency

**Parameters**:

============  =======  ===========  =========  ========================================================================
        Name     Type        Range    Default                                                               Description
============  =======  ===========  =========  ========================================================================
  separation    float      [0.,4.]         1.        Separation [arcsec] at date DATEOBS of observation of the binaries
          pa    float    [0.,360.]        4.8    Position angle [degree] at date DATEOBS of observation of the binaries
        Save      int        [0,1]          1                                     1: save output on disk, 0: don't save
       gpitv      int      [0,500]          2         1-500: choose gpitv session for displaying output, 0: no display 
============  =======  ===========  =========  ========================================================================


**IDL Filename**: gpi_calibrate_astrometry_from_binary_position.pro


.. index::
    single:Collapse datacube

.. _Collapsedatacube:

Collapse datacube
-----------------

 Collapse the wavelength dimension of a datacube via mean, median or total. 

**Category**:  ALL      **Order**: 2.6

**Inputs**:  any datacube

**Outputs**:  image containing that datacube collapsed to 2D      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


  TODO: more advanced collapse methods.


 GEM/GPI KEYWORDS:
 DRP KEYWORDS: CDELT3, CRPIX3,CRVAL3,CTYPE3,NAXIS3


 HISTORY:
  2010-04-23 JM created
  2011-07-30 MP: Updated for multi-extension FITS
  2013-07-12 MP: primitive rename for consistency

**Parameters**:

=============  ======  ==============  =========  ====================================================================
         Name    Type           Range    Default                                                           Description
=============  ======  ==============  =========  ====================================================================
       Method    enum    MEDIAN|TOTAL      TOTAL    How to collapse datacube: total or median (with flux conservation)
         Save     int           [0,1]          1                                 1: save output on disk, 0: don't save
  ReuseOutput     int           [0,1]          1                1: keep output for following primitives, 0: don't keep
        gpitv     int         [0,500]          2     1-500: choose gpitv session for displaying output, 0: no display 
=============  ======  ==============  =========  ====================================================================


**IDL Filename**: gpi_collapse_datacube.pro


.. index::
    single:Simple Spectral Differential Imaging

.. _SimpleSpectralDifferentialImaging:

Simple Spectral Differential Imaging
------------------------------------

 Apply SSDI to create a 2D subtracted image from a cube. Given the user's specified wavelength ranges, extract the 3D datacube slices for each of those wavelength ranges. Collapse these down into 2D images by simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1, then compute  diffImage = I1scaled - k* I2

**Category**:  SpectralScience      **Order**: 2.61

**Inputs**: 

**Outputs**:       **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


   This recipe rescales and subtracts 2 frames in different user-defined
   bandwidths. This recipe is used for speckle suppression using the
   Marois et al (2000) algorithm.

   This routine does NOT update the data structures in memory. You **MUST**
   set the keyword SAVE=1 or else the output is silently discarded.

     input datacube
     wavelength solution from common block

 KEYWORDS:
     L1Min=        Wavelength range 1, minimum wavelength [in microns]
     L1Max=        Wavelength range 1, maximum wavelength [in microns]
     L2Min=        Wavelength range 2, minimum wavelength [in microns]
     L2Max=        Wavelength range 2, maximum wavelength [in microns]
     k=            Multiplicative coefficient for multiplying the image for
                 Wavelength Range *2*. Default value is k=1.

     /Save        Set to 1 to save the output file to disk

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
   2013-08-07 ds: idl2 compiler compatible

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


**IDL Filename**: gpi_simple_spectral_differential_imaging.pro


.. index::
    single:Calibrate astrometry from binary (using 6th orbit catalog)

.. _Calibrateastrometryfrombinary(using6thorbitcatalog):

Calibrate astrometry from binary (using 6th orbit catalog)
----------------------------------------------------------

 Calculate astrometry from unocculted binaries; Calculate Separation and PA at date DATEOBS using the sixth orbit catalog.

**Category**:  Calibration      **Order**: 2.61

**Inputs**:  spectral mode datacube, observing a reference binary

**Outputs**:   plate scale & orientation, saved as calibration file      **Output Suffix**: 'astrom' ; output suffix

**Notes**:

.. code-block:: idl





 GEM/GPI KEYWORDS:CRPA,DATE-OBS,OBJECT,TIME-OBS
 DRP KEYWORDS: FILETYPE,ISCALIB


 HISTORY:
 	Originally by Jerome Maire 2009-12
 	2013-07-19 MP: Rename for consistency

**Parameters**:

======  ======  =======  =========  =======================================
  Name    Type    Range    Default                              Description
======  ======  =======  =========  =======================================
  Save     int    [0,1]          1    1: save output on disk, 0: don't save
======  ======  =======  =========  =======================================


**IDL Filename**: gpi_calibrate_astrometry_from_binary_orbit_catalog.pro


.. index::
    single:Speckle alignment

.. _Specklealignment:

Speckle alignment
-----------------

 This recipe rescales datacube PSF slices with respect to a chosen reference PSF slice.

**Category**:  SpectralScience      **Order**: 2.61

**Inputs**:   Spectral datacube

**Outputs**:  Resampled and rescaled spectral datacube      **Output Suffix**:  suffix+'-specalign'

**Notes**:

.. code-block:: idl


 	This recipe rescales datacube slices with respect to a chosen reference slice.


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


**IDL Filename**: gpi_speckle_alignment.pro


.. index::
    single:Measure Contrast

.. _MeasureContrast:

Measure Contrast
----------------

 Measure the contrast. Save as PNG or FITS table.

**Category**:  SpectralScience,PolarimetricScience      **Order**: 2.7

**Inputs**:  Spectral mode datacube

**Outputs**:  	Contrast datacube, plot of contrast curve      **Output Suffix**: '-contr'

**Notes**:

.. code-block:: idl


	Measure, display on screen, and optionally save the contrast.

   TODO - should we revise this to call the same contrast measurement backend
   as GPItv?




 HISTORY:
 	initial version imported GPItv (with definition of contrast corrected) - JM

**Parameters**:

==================  ========  ==========  ============  ===================================================================================================================
              Name      Type       Range       Default                                                                                                          Description
==================  ========  ==========  ============  ===================================================================================================================
              Save       int       [0,1]             0                                                                                1: save output on disk, 0: don't save
           Display       int    [-1,100]            -1                                        -1 = No display; 0 = New (unused) window; else = Window number to display in.
       SaveProfile    string        None                  Save radial profile to filename as FITS (blank for no save, dir name for default naming, AUTO for auto full path)
           SavePNG    string        None                            Save plot to filename as PNG (blank for no save, dir name for default naming, AUTO for auto full path) 
        contrsigma     float    [0.,20.]            5.                                                                                                 Contrast sigma limit
             slice       int     [-1,50]             0                                                                                            Slice to plot. -1 for all
      DarkHoleOnly       int       [0,1]             1                                                    0: Plot profile in dark hole only; 1: Plot outer profile as well.
       contr_yunit       int       [0,2]             0                                                                           0: Standard deviation; 1: Median; 2: Mean.
       contr_xunit       int       [0,1]             0                                                                                              0: Arcsec; 1: lambda/D.
            yscale       int       [0,1]             0                                                                           0: Auto y axis scaling; 1: Manual scaling.
  contr_yaxis_type       int       [0,1]             1                                                                                                    0: Linear; 1: Log
   contr_yaxis_min     float     [0.,1.]    0.00000001                                                                                                       Y axis minimum
   contr_yaxis_max     float     [0.,1.]            1.                                                                                                       Y axis maximum
==================  ========  ==========  ============  ===================================================================================================================


**IDL Filename**: gpi_measure_contrast.pro


.. index::
    single:Plot the satellite spot locations vs. the expected location from wavelength scaling

.. _Plotthesatellitespotlocationsvs.theexpectedlocationfromwavelengthscaling:

Plot the satellite spot locations vs. the expected location from wavelength scaling
-----------------------------------------------------------------------------------

 Measured vs. wavelength scaled sat spot locations

**Category**:  SpectralScience      **Order**: 2.7

**Inputs**:  Spectral mode datacube

**Outputs**:  Plot of results.

**Notes**:

.. code-block:: idl

	This is a quality check routine that verifies the expected wavelength
	scaling of the datacube, based on how the satellite spots locations
	vary with wavelength.


 KEYWORDS:






 HISTORY:
 	written 12/11/2012 - ds

**Parameters**:

==========  ========  ==========  =========  ===============================================================================
      Name      Type       Range    Default                                                                      Description
==========  ========  ==========  =========  ===============================================================================
   Display       int    [-1,100]          1    -1 = No display; 0 = New (unused) window; else = Window number to display in.
  SaveData    string        None                                                   Save data to filename (blank for no save)
   SavePNG    string        None                                             Save plot to filename as PNG(blank for no save)
==========  ========  ==========  =========  ===============================================================================


**IDL Filename**: gpi_meas_satspot_dev.pro


.. index::
    single:KLIP algorithm Spectral Differential Imaging

.. _KLIPalgorithmSpectralDifferentialImaging:

KLIP algorithm Spectral Differential Imaging
--------------------------------------------

 Reduce speckle noise using the KLIP algorithm across the spectral axis of a datacube.

**Category**:  SpectralScience      **Order**: 2.8

**Inputs**:  Spectral datacube

**Outputs**:   Spectral datacube after SDI PSF subtraction      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


   This algorithm reduces PSF speckles in a datacube using the
   KLIP algorithm and Spectral Differential Imaging.


 ALGORITHM:
       Measure annuli out from the center of the cube and create a
       reference set for each annuli of each slice. Apply KLIP to the
       reference set and project the target slice onto the KL
       transform vector. Subtract the projected image from the
       original and repeat for all slices


 HISTORY:
        Written 2013. Tyler Barker
        2013-07-18 MP: Renamed for consistency

**Parameters**:

==========  =======  ===========  =========  ===================================================================
      Name     Type        Range    Default                                                          Description
==========  =======  ===========  =========  ===================================================================
      Save      int        [0,1]          1                                1: save output on disk, 0: don't save
  refslice      int      [0,100]          0                                           Slice of the reference PSF
    annuli      int      [0,100]          5                                                Number of annuli used
  movement    float    [0.0,5.0]        2.0                             Minimum pixel movement for reference set
      prop    float    [0.8,1.0]     .99999      Proportion of eigenvalues used to truncate KL transform vectors
    arcsec    float    [0.0,1.0]         .4                                Radius of interest if using 1 annulus
    signal      int        [0,1]          0              1: calculate signal to noise ration, 0: don't calculate
     gpitv      int      [0,500]          5    1-500: choose gpitv session for displaying output, 0: no display 
==========  =======  ===========  =========  ===================================================================


**IDL Filename**: gpi_klip_algorithm_spectral_differential_imaging.pro


.. index::
    single:Update World Coordinates

.. _UpdateWorldCoordinates:

Update World Coordinates
------------------------

 Add wcs info, assuming target star is precisely centered.

**Category**:  ALL      **Order**: 2.9

**Inputs**:   Any datacube

**Outputs**:  Datacube with updated WCS keywords in header      **Output Suffix**: '-addwcs'              ; output suffix

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
   2013-07-18 MP: Rename for consistency
   2013-08-07 ds: idl2 compiler compatible
	2013-12-30 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    string       None    AUTOMATIC                           Name of astrometry offset calibratoin file
             Save       int      [0,1]            0                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            0    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: gpi_update_world_coordinates.pro


.. index::
    single:Stores calibration in dataset

.. _Storescalibrationindataset:

Stores calibration in dataset
-----------------------------

 Stores the current calibration into the dataset structure.

**Category**:  Calibration      **Order**: 3.0

**Inputs**:  data-cube

**Outputs**: 

**Notes**:

.. code-block:: idl


 To be called before an accumulate image.
 It is used for high resolution microlens PSF determination

 common needed:

 KEYWORDS:


 HISTORY:
     Originally by Jean-Baptiste Ruffio 2013-08

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: store_calib_in_dataset.pro


.. index::
    single:Create Lenslet Flat Field

.. _CreateLensletFlatField:

Create Lenslet Flat Field
-------------------------

 Create a 2D flat field for wavelength-independent lenslet throughput variations.

**Category**:  Calibration      **Order**: 3.1992

**Inputs**:  Flat lamp data

**Outputs**:  2D lenslet flat field file      **Output Suffix**: 'lensletflat'

**Notes**:

.. code-block:: idl


	Creates a simple derived flat field for non-uniform transmission in the
	lenslets.

	WARNING: experimental code, probably not yet ready for prime time.



 HISTORY:
    2014-01-02 MP: Created

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_create_lenslet_flat_field.pro


.. index::
    single:Normalize polarimetry flat field

.. _Normalizepolarimetryflatfield:

Normalize polarimetry flat field
--------------------------------

 Normalize a polarimetry-mode flat field to unity.

**Category**:  Calibration      **Order**: 3.1992

**Inputs**:  polarimetry data-cube with flat lamp

**Outputs**:   Normalized polarimetry mode flat field      **Output Suffix**: 'polflat'

**Notes**:

.. code-block:: idl



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


**IDL Filename**: gpi_normalize_polarimetry_flat_field.pro


.. index::
    single:Smooth a 3D Cube

.. _Smootha3DCube:

Smooth a 3D Cube
----------------

 Smooth a cube by convolution with a Gaussian kernel, repeated for each slice of the cube.

**Category**:  PolarimetricScience,SpectralScience,Calibration      **Order**: 3.5

**Inputs**:  data-cube

**Outputs**:   smoothed datacube      **Output Suffix**:  'clean'

**Notes**:

.. code-block:: idl


 Convolves images with a gaussian kernel

	Note: This primitive will work properly either before or after Accumulate
	Images. If after, it will smooth all accumulated images.


 GEM/GPI KEYWORDS:
 DRP KEYWORDS: HISTORY



 HISTORY:
   2014-01-09 MMB created
   2014-04-28 MP: Minor documentation updates

**Parameters**:

=============  ======  =========  =========  ===================================================================
         Name    Type      Range    Default                                                          Description
=============  ======  =========  =========  ===================================================================
  Smooth_FWHM     int    [0,100]          3                                              FWHM of gaussian kernel
         Save     int      [0,1]          1                                1: save output on disk, 0: don't save
        gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=============  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_smooth_cube.pro


.. index::
    single:Divide by Polarized Flat Field

.. _DividebyPolarizedFlatField:

Divide by Polarized Flat Field
------------------------------

 Divides a 2-slice polarimetry file by a flat field.

**Category**:  PolarimetricScience, Calibration      **Order**: 3.5

**Inputs**:  data-cube

**Outputs**:   datacube with slices flat-fielded

**Notes**:

.. code-block:: idl


   ** Needs additional work, will not produce high qualty results yet **


 GEM/GPI KEYWORDS:
 DRP KEYWORDS: HISTORY



 HISTORY:
   2009-07-22: MDP created
   2009-09-17 JM: added DRF parameters
   2009-10-09 JM added gpitv display
   2010-10-19 JM: split HISTORY keyword if necessary
   2011-07-30 MP: Updated for multi-extension FITS
   2013-07-12 MP: Rename for consistency
   2013-12-16 MP: CalibrationFile argument syntax update.

**Parameters**:

=================  ========  =========  ===========  ===================================================================
             Name      Type      Range      Default                                                          Description
=================  ========  =========  ===========  ===================================================================
  CalibrationFile    String       None    AUTOMATIC       Filename of the desired wavelength calibration file to be read
             Save       int      [0,1]            1                                1: save output on disk, 0: don't save
            gpitv       int    [0,500]            2    1-500: choose gpitv session for displaying output, 0: no display 
=================  ========  =========  ===========  ===================================================================


**IDL Filename**: gpi_divide_by_polarized_flat_field.pro


.. index::
    single:Rotate North Up

.. _RotateNorthUp:

Rotate North Up
---------------

 Rotate datacubes so that north is up and east is left. 

**Category**:  SpectralScience,PolarimetricScience      **Order**: 3.9

**Inputs**:  Datacube(s) in either spectral or polarimetric mode

**Outputs**:  Rotated datacube(s) with north up and east left.      **Output Suffix**:  '-northup'

**Notes**:

.. code-block:: idl


   Rotate so that North is Up, and east is to the left.
   If necessary this will flip handedness as well as rotate
   to get the right parity in the output image.

	Note that this primitive can go *either* before or after
	Accumulate Images. As a Level 1 primitive, it will rotate
	one cube at a time; as a Level 2 primitive it will rotate
	the whole stack of accumulated images all at once (though
	it rotates each one by its own particular rotation angle).


 KEYWORDS:
 GEM/GPI KEYWORDS:RA,DEC,PAR_ANG
 DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,NAXIS1,NAXIS2,PC1_1,PC1_2,PC2_1,PC2_2


 HISTORY:

**Parameters**:

===============  ========  ================  =========  ==========================================================================
           Name      Type             Range    Default                                                                 Description
===============  ========  ================  =========  ==========================================================================
     Rot_Method    string         CUBIC|FFT      CUBIC                                              Method to compute the rotation
  Center_Method    string    HEADERS|MANUAL    HEADERS    Determine the center of rotation from FITS header keywords, manual entry
        centerx       int           [0,281]        140                                      Center X Pixel if Center_Method=Manual
        centery       int           [0,281]        140                                      Center Y Pixel if Center_Method=Manual
          pivot       int             [0,1]          0                                 Pivot about the center of the image? 0 = No
           Save       int             [0,1]          0                                                                        None
          gpitv       int           [0,500]          2           1-500: choose gpitv session for displaying output, 0: no display 
===============  ========  ================  =========  ==========================================================================


**IDL Filename**: gpi_rotate_north_up.pro


.. index::
    single:Rotate Field of View Square

.. _RotateFieldofViewSquare:

Rotate Field of View Square
---------------------------

 Rotate datacubes so that the field of view is squarely aligned with the image axes. 

**Category**:  SpectralScience,PolarimetricScience      **Order**: 3.9

**Inputs**:  datacube

**Outputs**:  Rotated datacube      **Output Suffix**:  '_rot'

**Notes**:

.. code-block:: idl


    Rotate by the lenslet/field relative angle, so that the GPI IFS
    field of view is roughly square with the pixel coordinate axes.



 KEYWORDS:
 GEM/GPI KEYWORDS:RA,DEC,PAR_ANG
 DRP KEYWORDS: CDELT1,CDELT2,CRPIX1,CRPIX2,CRVAL1,CRVAL2,NAXIS1,NAXIS2,PC1_1,PC1_2,PC2_1,PC2_2


 HISTORY:
   2012-04-10 MDP: Created, based on rotate_north_up.pro
   2013-11-07 ds - updated to use gpi_update_wcs_basic

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


**IDL Filename**: gpi_rotate_field_of_view_square.pro


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
   2009-07-22 MDP: started
   2009-09-17 JM: added DRF parameters
   2013-08, 2013-10 MDP: Minor code formatting cleanup

**Parameters**:

========  ========  =================  ==========  =================
    Name      Type              Range     Default        Description
========  ========  =================  ==========  =================
  Method    string    OnDisk|InMemory    InMemory    OnDisk|InMemory
========  ========  =================  ==========  =================


**IDL Filename**: gpi_accumulate_images.pro


.. index::
    single:Create 2D Low Frequency Flat

.. _Create2DLowFrequencyFlat:

Create 2D Low Frequency Flat
----------------------------

 Create Low Frequency Flat 2D from polarimetry flats

**Category**:  HIDDEN      **Order**: 4.01

**Inputs**:   Polarimetry flats

**Outputs**:  Low frequency flat      **Output Suffix**:  '-LFFlat'

**Notes**:

.. code-block:: idl


 /!\ PROBABLY OUT OF DATE /!\ /!\ PROBABLY OUT OF DATE /!\
 That's why it is hidden. It was not even ready for release.
 See new LF flat determination with the work in progress by JB and Patrick on high resolution microlens PSF.
 /!\ PROBABLY OUT OF DATE /!\ /!\ PROBABLY OUT OF DATE /!\

 This primitive use a combined image of polarimetry flat-fields to build a low frequency flat for the detector array.
 The idea applied here is to integrate the flux of each single spot using aperture photometry. For every spot, the neighbors are masked and the function aper computes the total flux and the sky/background correction. The neighbors are masked in order to have enough pixels to compute the sky. Then, we combine the flux of every couple of spots.
 Then, we divide all the values with their median.
 Artifacts are removed by computing a local std deviation and median. Every pixels further than n-sigma were replaced by the value of the smoothed flat.
 To finish, we interpolates the resulting values over the 2048x2048 detector array using triangulate/trigrid function (linear interpolation using nearest neighbors).

 There are still borders problem. The flat is not valid near the edges.



 HISTORY:
     Originally by Jean-Baptiste Ruffio 2013-06
     2013-07-17 MP: Renamed for consistency
	  2013-12-03 MP: Add check for GCALLAMP=QH on input images

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_create_2d_low_frequency_flat.pro


.. index::
    single:Creates a thermal/sky background datacube

.. _Createsathermal/skybackgrounddatacube:

Creates a thermal/sky background datacube
-----------------------------------------

 Create Sky/Thermal background cubes 

**Category**:  Calibration      **Order**: 4.01

**Inputs**:   A 2D sky image (should be a combination of several frames)

**Outputs**:  A master sky frame, saved as a calibration file      **Output Suffix**:  '-bkgnd_cube'

**Notes**:

.. code-block:: idl


 Create a thermal/sky background cube (3D) rather than using 2D detector frames as is done using the Combine 2D Thermal/Sky Backgrounds primitive. This allows a smoothing of the sky frame that will decrease the photon noise.



 HISTORY:
   2013-12-23 PI: Created Primitive

**Parameters**:

=================  ======  =========  =========  ===================================================================
             Name    Type      Range    Default                                                          Description
=================  ======  =========  =========  ===================================================================
  smooth_box_size     int    [0,100]          3                              Size of box to smooth by (0: No smooth)
             Save     int      [0,1]          1                                1: save output on disk, 0: don't save
            gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=================  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_create_sky_bkgd_cube.pro


.. index::
    single:Find Cold Bad Pixels from Flats

.. _FindColdBadPixelsfromFlats:

Find Cold Bad Pixels from Flats
-------------------------------

 Find cold pixels from a stack of flat images using all different filters

**Category**:  Calibration      **Order**: 4.01

**Inputs**:  Flat field images, preferably in multiple filters

**Outputs**:  Map of cold bad pixels      **Output Suffix**: '-coldpix'

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





 HISTORY:
  2013-03-08 MP: Implemented in pipeline based on algorithm from Christian
  2013-12-03 MP: Add check for GCALLAMP=QH on input images

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_find_cold_bad_pixels_from_flats.pro


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
  either a mean or median algorithm, or a mean with outlier
  rejection (sigma clipping)

  Also, based on the variance between the various dark frames, the
  read noise is estimated, and a list of hot pixels is derived.
  The read noise and number of significantly hot pixels are written
  as keywords to the FITS header for use in trending analyses.
  CAUTION FIXME: this code does not take into account coadds properly
  and thus is underestimating the actual read noise per frame.




 HISTORY:
 	 Jerome Maire 2008-10
   2009-09-17 JM: added DRF parameters
   2009-10-22 MDP: Created from mediancombine_darks, converted to use
   				accumulator.
   2010-01-25 MDP: Added support for multiple methods, MEAN method.
   2010-03-08 JM: ISCALIB flag for Calib DB
   2011-07-30 MP: Updated for multi-extension FITS
   2013-07-12 MP: Rename for consistency
	2013-12-15 MP: Implemented SIGMACLIP, doc header updates.

**Parameters**:

===========  ========  =======================  ===========  ===============================================================================================================================================
       Name      Type                    Range      Default                                                                                                                                      Description
===========  ========  =======================  ===========  ===============================================================================================================================================
     Method    string    MEAN|MEDIAN|SIGMACLIP    SIGMACLIP                                                      How to combine images: median, mean, or mean with outlier rejection?[MEAN|MEDIAN|SIGMACLIP]
  Sigma_cut     float                  [1,100]            3    If Method=SIGMACLIP, then data points more than this many standard deviations away from the median value of a given pixel will be discarded. 
       Save       int                    [0,1]            1                                                                                                            1: save output on disk, 0: don't save
      gpitv       int                  [0,500]            2                                                                                1-500: choose gpitv session for displaying output, 0: no display 
===========  ========  =======================  ===========  ===============================================================================================================================================


**IDL Filename**: gpi_combine_2d_dark_images.pro


.. index::
    single:Find Hot Bad Pixels from Darks

.. _FindHotBadPixelsfromDarks:

Find Hot Bad Pixels from Darks
------------------------------

 Find hot pixels from a stack of dark images (best with deep integration darks)

**Category**:  Calibration      **Order**: 4.01

**Inputs**:  Multiple dark images

**Outputs**: 	Map of hot bad pixels      **Output Suffix**: '-hotpix'

**Notes**:

.. code-block:: idl


 This is a variant of combinedarkframes that (instead of combining darks)
 analyzes them to find hot pixels and then writes out a
 mask showing where the various hot pixels are.


 The current algorithm determines pixels that are hot according to the
 criteria:
	(a) dark count rate must be > 1 e-/second for that pixel
	(b) that must be measured with >5 sigma confidence above the estimated
	    read noise of the frames.
 The first criterion can be adjusted using the hot_bad_thresh argument.




 HISTORY:
   2009-07-20 JM: created
   2009-09-17 JM: added DRF parameters
   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
   2012-11-15 MP: Algorithm entirely replaced with one based on combinedarkframes.

**Parameters**:

================  =======  ==========  =========  ===================================================================
            Name     Type       Range    Default                                                          Description
================  =======  ==========  =========  ===================================================================
            Save      int       [0,1]          1                                1: save output on disk, 0: don't save
  hot_bad_thresh    float    [0,100.]        1.0         Threshhold to consider a hot pixel bad, in electrons/second.
           gpitv      int     [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
================  =======  ==========  =========  ===================================================================


**IDL Filename**: gpi_find_hot_bad_pixels_from_darks.pro


.. index::
    single:Create microphonics noise model

.. _Createmicrophonicsnoisemodel:

Create microphonics noise model
-------------------------------

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
     2013-07-17 MP: Rename for consistency

**Parameters**:

==================  ========  ============  =========  ===========================================================================
              Name      Type         Range    Default                                                                  Description
==================  ========  ============  =========  ===========================================================================
      Gauss_Interp       int         [0,1]          0              1: Interpolate each peak by a 2d gaussian, 0: don't interpolate
  Combining_Method    string    ADD|MEDIAN        ADD    Method to combine the Fourier transforms of the microphonics (ADD|MEDIAN)
              Save       int         [0,1]          1                                        1: save output on disk, 0: don't save
             gpitv       int       [0,500]          2            1-500: choose gpitv session for displaying output, 0: no display 
==================  ========  ============  =========  ===========================================================================


**IDL Filename**: gpi_create_microphonics_noise_model.pro


.. index::
    single:Generate Combined Bad Pixel Map

.. _GenerateCombinedBadPixelMap:

Generate Combined Bad Pixel Map
-------------------------------

 This routine combines various sub-types of bad pixel mask (hot, cold,  anomalous nonlinear pixels) to generate a master bad pixel list.

**Category**:  Calibration      **Order**: 4.02

**Inputs**:  bad pixel maps

**Outputs**:  Combined bad pixel map      **Output Suffix**:  '-badpix'

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



 HISTORY:
    Jerome Maire 2009-08-10
   2009-09-17 JM: added DRF parameters
   2012-01-31 Switched sxaddpar to backbone->set_keyword Dmitry Savransky
   2012-11-19 MP: Complete algorithm overhaul.
   2013-04-29 MP: Better error checking; nonlinearbadpix is optional.
   2013-07-12 MP: rename for consistency

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_generate_combined_bad_pixel_map.pro


.. index::
    single:Clean Polarization Pairs via Double Difference

.. _CleanPolarizationPairsviaDoubleDifference:

Clean Polarization Pairs via Double Difference
----------------------------------------------



**Category**:  PolarimetricScience,Calibration      **Order**: 4.05

**Inputs**:   Multiple polarization pair datacubes

**Outputs**:  Multiple polarization pair datacubes, hopefully with reduced      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	Given a sequence of polarization pair cubes, use a modified double
	differencing approach to mitigate systematics between the e- and o- ray
	channels of the cubes.

	This must be used after Accumulate Images. Unlike most such primitives, it
	acts on the entire stack of cubes at once without combining them yet.

	This must be used prior to rotating the cubes if it is to have any hope at
	all of working well.

	**Caution** Experimental/Under Development code - algorithms may still be in
	flux.

		   systematics





 HISTORY:
	2013-03-20	Started by Marshall, forked from gpi_combine_polarizations_dd.pro

**Parameters**:

================  ======  =========  =========  ========================================================================================================
            Name    Type      Range    Default                                                                                               Description
================  ======  =========  =========  ========================================================================================================
      fix_badpix     int      [0,1]          1                                  Also locate statistical outlier bad pixels and repair via interpolation?
   Save_diffbias     int      [0,1]          0                             Save the difference image systematic bias estimate subtracted from each pair?
  gpitv_diffbias     int    [0,500]         10    Display empirical systematic bias in difference frames in a GPITV session 1-500, or 0 for  no display 
            Save     int      [0,1]          1                                                                     1: save output on disk, 0: don't save
           debug     int      [0,1]          0                                                                        Stop at breakpoints for debug/test
================  ======  =========  =========  ========================================================================================================


**IDL Filename**: gpi_clean_polarization_pairs_dd.pro


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

 		ADI algorithm based on original Marois et al (2006) paper.



 KEYWORDS:
 GEM/GPI KEYWORDS:FILTER,PAR_ANG,TELDIAM
 DRP KEYWORDS: PSFCENTX,PSFCENTY


 HISTORY:
 	 Adapted for GPI - Jerome Maire 2008-08
    multiwavelength - JM
   2009-09-17 JM: added DRF parameters
    2010-04-26 JM: verify how many spectral channels to process and adapt ADI for that,
                so we can use ADI on collapsed datacubes or SDI
                outputs
   2013-08-07 ds: idl2 compiler compatible

**Parameters**:

==========  =======  =========  =========  ============================================================================
      Name     Type      Range    Default                                                                   Description
==========  =======  =========  =========  ============================================================================
  numimmed      int    [1,100]          3                     number of images for the calculation of the PSF reference
     nfwhm    float     [0,20]        1.5    number of FWHM to calculate the minimal distance for reference calculation
      Save      int      [0,1]          1                                         1: save output on disk, 0: don't save
     gpitv      int    [0,500]         10             1-500: choose gpitv session for displaying output, 0: no display 
==========  =======  =========  =========  ============================================================================


**IDL Filename**: gpi_basic_adi.pro


.. index::
    single:ADI with LOCI

.. _ADIwithLOCI:

ADI with LOCI
-------------

 Implements the LOCI ADI algorithm (Lafreniere et al. 2007)

**Category**:  SpectralScience      **Order**: 4.11

**Inputs**:  data-cube

**Outputs**: Not specified      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl

 		ADI algorithm based on Lafreniere et al. 2007.


 Code currently only offers the use of positive and negative coefficients.



 KEYWORDS:
 GEM/GPI KEYWORDS:COADDS,CRFOLLOW,DEC,EXPTIME,HA,PAR_ANG
 DRP KEYWORDS: HISTORY,PSFCENTX,PSFCENTY



 HISTORY:
 	 Jerome Maire :- multiwavelength 2008-08
   JM: adapted for GPI-pip
   2009-09-17 JM: added DRF parameters
   2010-04-26 JM: verify how many spectral channels to process and adapt LOCI for that,
                so we can use LOCI on collapsed datacubes or SDI outputs
   2013-07-17 MP: Rename for consistency
   2013-08-07 ds: idl2 compiler compatible, added start_primitive

**Parameters**:

============  =======  =========  =========  ============================================================================
        Name     Type      Range    Default                                                                   Description
============  =======  =========  =========  ============================================================================
       nfwhm    float     [0,20]        1.5    number of FWHM to calculate the minimal distance for reference calculation
  coeff_type      int      [0,1]          0      0: positive and negative 1: positive only Coefficients in LOCI algorithm
        Save      int      [0,1]          1                                         1: save output on disk, 0: don't save
       gpitv      int    [0,500]         10             1-500: choose gpitv session for displaying output, 0: no display 
============  =======  =========  =========  ============================================================================


**IDL Filename**: gpi_adi_with_loci.pro


.. index::
    single:Populate Flexure Shifts vs Elevation Table

.. _PopulateFlexureShiftsvsElevationTable:

Populate Flexure Shifts vs Elevation Table
------------------------------------------

 Derive shifts vs elevation lookup table.

**Category**:  Calibration      **Order**: 4.2

**Inputs**: Not specified

**Outputs**: Not specified      **Output Suffix**:  '-shifts'

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




 HISTORY:
      Jerome Maire 2013-02
      2013-07-17 MP: Rename for consistency

**Parameters**:

===========  ========  ==========  =========  ==============================================================================================
       Name      Type       Range    Default                                                                                     Description
===========  ========  ==========  =========  ==============================================================================================
       Save       int       [0,1]          1                                                           1: save output on disk, 0: don't save
    Display       int    [-1,100]          1    -1 = No display; 0 = New (unused) window else = Window number to display diagnostic plot in.
  saveplots    string    [yes|no]         no                                       Save diagnostic plots to PS files after running? [yes|no]
===========  ========  ==========  =========  ==============================================================================================


**IDL Filename**: gpi_populate_flexure_shifts_vs_elevation_table.pro


.. index::
    single:Advanced KLIP ADI for Pol Mode

.. _AdvancedKLIPADIforPolMode:

Advanced KLIP ADI for Pol Mode
------------------------------

 Reduce speckle noise using the KLIP algorithm with ADI data

**Category**:  PolarimetricScience      **Order**: 4.2

**Inputs**:  Multiple spectral datacubes

**Outputs**:  A reduced datacube with reduced PSF speckle halo      **Output Suffix**:  suffix+'-klip'

**Notes**:

.. code-block:: idl


   This algorithm reduces PSF speckles in a datacube using the
   KLIP algorithm and Angular Differential Imaging in Pol Mode

 ALGORITHM:
       Star location must have been previously measured using satellite spots.
       Measure annuli out from the center of the cube and create a
       reference set for each annuli of each slice. Apply KLIP to the
       reference set and project the target slice onto the KL
       transform vector. Subtract the projected image from the
       original and repeat for all slices




 HISTORY:
        2013-10-21 - ds
        2014-03-23 - MMB: Started adjusting for pol mode

**Parameters**:

=============  ========  =============  ==============  ===============================================================================
         Name      Type          Range         Default                                                                      Description
=============  ========  =============  ==============  ===============================================================================
         Save       int          [0,1]               0                                            1: save output on disk, 0: don't save
       annuli       int        [0,100]               0                                                          Number of annuli to use
  MinRotation     float    [0.0,360.0]               1                                        Minimum rotation between images (degrees)
  CollapsePol       int          [0,1]               0                   Collapse the pol cube and perform KLIP on the total intensity?
         Mask       int          [0,1]               0    Do you want to mask out any area? If so you must provide a list of mask files
     MaskList    string           None    MaskList.txt        The name of a file containing a list of mask files corresponding to each 
         prop     float      [0.8,1.0]          .99999                  Proportion of eigenvalues used to truncate KL transform vectors
        gpitv       int        [0,500]               5                1-500: choose gpitv session for displaying output, 0: no display 
=============  ========  =============  ==============  ===============================================================================


**IDL Filename**: gpi_klip_adi_pol_adv.pro


.. index::
    single:KLIP algorithm Angular Differential Imaging

.. _KLIPalgorithmAngularDifferentialImaging:

KLIP algorithm Angular Differential Imaging
-------------------------------------------

 Reduce speckle noise using the KLIP algorithm with ADI data

**Category**:  SpectralScience      **Order**: 4.2

**Inputs**:  Multiple spectral datacubes

**Outputs**:  A reduced datacube with reduced PSF speckle halo      **Output Suffix**:  suffix+'-klip'

**Notes**:

.. code-block:: idl


   This algorithm reduces PSF speckles in a datacube using the
   KLIP algorithm and Angular Differential Imaging.

 ALGORITHM:
       Star location must have been previously measured using satellite spots.
       Measure annuli out from the center of the cube and create a
       reference set for each annuli of each slice. Apply KLIP to the
       reference set and project the target slice onto the KL
       transform vector. Subtract the projected image from the
       original and repeat for all slices




 HISTORY:
        2013-10-21 - ds

**Parameters**:

=============  =======  =============  =========  ===================================================================
         Name     Type          Range    Default                                                          Description
=============  =======  =============  =========  ===================================================================
         Save      int          [0,1]          0                                1: save output on disk, 0: don't save
       annuli      int        [0,100]          0                                              Number of annuli to use
  MinRotation    float    [0.0,360.0]          1                            Minimum rotation between images (degrees)
         prop    float      [0.8,1.0]     .99999      Proportion of eigenvalues used to truncate KL transform vectors
        gpitv      int        [0,500]          5    1-500: choose gpitv session for displaying output, 0: no display 
=============  =======  =============  =========  ===================================================================


**IDL Filename**: gpi_klip_algorithm_angular_differential_imaging.pro


.. index::
    single:KLIP algorithm Angular Differential Imaging With Center Forced

.. _KLIPalgorithmAngularDifferentialImagingWithCenterForced:

KLIP algorithm Angular Differential Imaging With Center Forced
--------------------------------------------------------------

 Reduce speckle noise using the KLIP algorithm with ADI data with center forced to image center

**Category**:  SpectralScience      **Order**: 4.2

**Inputs**:  Multiple spectral datacubes

**Outputs**:  A reduced datacube with reduced PSF speckle halo      **Output Suffix**:  suffix+'-klip'

**Notes**:

.. code-block:: idl


   This algorithm reduces noise in a datacube using the
   KLIP algorithm and Angular Differential Imaging.
   This is the same as the 'KLIP algorithm Angular Differential Imaging'
   primitive, except the location of the star can be entered manually.
   This can be useful for data with low S/N where the satellite
   spots are not found automatically.

   Used during first light run, may not be that generally applicable
   now that automatic satellite spot finding is much more robust.


 ALGORITHM:
       Measure annuli out from the center of the cube and create a
       reference set for each annuli of each slice. Apply KLIP to the
       reference set and project the target slice onto the KL
       transform vector. Subtract the projected image from the
       original and repeat for all slices


 HISTORY:
        2013-11-16- ds  Developed on the fly during first light run

**Parameters**:

=============  =======  =============  =========  ===================================================================
         Name     Type          Range    Default                                                          Description
=============  =======  =============  =========  ===================================================================
         Save      int          [0,1]          0                                1: save output on disk, 0: don't save
       annuli      int        [0,100]          0                                              Number of annuli to use
      centerx      int        [0,281]        140                                                       Center X Pixel
      centery      int        [0,281]        140                                                       Center Y Pixel
  MinRotation    float    [0.0,360.0]          1                            Minimum rotation between images (degrees)
         prop    float      [0.8,1.0]     .99999      Proportion of eigenvalues used to truncate KL transform vectors
        gpitv      int        [0,500]          5    1-500: choose gpitv session for displaying output, 0: no display 
=============  =======  =============  =========  ===================================================================


**IDL Filename**: gpi_klip_algorithm_angular_differential_imaging_forcecent.pro


.. index::
    single:KLIP ADI for Pol Mode

.. _KLIPADIforPolMode:

KLIP ADI for Pol Mode
---------------------

 Reduce speckle noise using the KLIP algorithm with ADI data

**Category**:  PolarimetricScience      **Order**: 4.2

**Inputs**:  Multiple spectral datacubes

**Outputs**:  A reduced datacube with reduced PSF speckle halo      **Output Suffix**:  suffix+'-klip'

**Notes**:

.. code-block:: idl


   This algorithm reduces PSF speckles in a datacube using the
   KLIP algorithm and Angular Differential Imaging in Pol Mode

 ALGORITHM:
       Star location must have been previously measured using satellite spots.
       Measure annuli out from the center of the cube and create a
       reference set for each annuli of each slice. Apply KLIP to the
       reference set and project the target slice onto the KL
       transform vector. Subtract the projected image from the
       original and repeat for all slices




 HISTORY:
        2013-10-21 - ds
        2014-03-23 - MMB: Started adjusting for pol mode

**Parameters**:

=============  =======  =============  =========  ===================================================================
         Name     Type          Range    Default                                                          Description
=============  =======  =============  =========  ===================================================================
         Save      int          [0,1]          0                                1: save output on disk, 0: don't save
       annuli      int        [0,100]          0                                              Number of annuli to use
  MinRotation    float    [0.0,360.0]          1                            Minimum rotation between images (degrees)
  CollapsePol      int          [0,1]          0       Collapse the pol cube and perform KLIP on the total intensity?
         prop    float      [0.8,1.0]     .99999      Proportion of eigenvalues used to truncate KL transform vectors
        gpitv      int        [0,500]          5    1-500: choose gpitv session for displaying output, 0: no display 
=============  =======  =============  =========  ===================================================================


**IDL Filename**: gpi_klip_algorithm_angular_differential_imaging_pol.pro


.. index::
    single:Combine Wavelength Calibrations

.. _CombineWavelengthCalibrations:

Combine Wavelength Calibrations
-------------------------------

 Performs simple median combination of wavelength calibrations from flat and/or arc lamps

**Category**:  Calibration      **Order**: 4.2

**Inputs**:  Multiple 3D wavcal cubes

**Outputs**:  One merged 3D wavecal cube

**Notes**:

.. code-block:: idl


 gpi_combine_wavcal_all is a simple median combination of wav. cal. files obtained with flat and arc images.
  TO DO: exclude some mlens from the median in case of  wavcal

  This is **mostly deprecated**: in general it is recommended to combine
  all 2D images for a given arc lamp and then derive one wavelength solution
  from those, rather than deriving multiple wavecals and then combining them.
  On the other hand if you want to merge wavecals from two different lamps then
  you can indeed use this.


 GEM/GPI KEYWORDS:DATE-OBS,FILTER,IFSFILT,TIME-OBS
 DRP KEYWORDS: DATAFILE


 HISTORY:
    Jerome Maire 2009-08-10
   2009-09-17 JM: added DRF parameters
   2012-10-17 MP: Removed deprecated suffix= keyword
   2013-07-17 MP: Rename for consistency

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_combine_wavelength_calibrations.pro


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
   2013-08-07 ds: idl2 compiler compatible

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
    single:Simple SDI of post ADI residual

.. _SimpleSDIofpostADIresidual:

Simple SDI of post ADI residual
-------------------------------

 Apply SSDI to create a 2D subtracted image from a cube. Given the user's specified wavelength ranges, extract the 3D datacube slices for each of those wavelength ranges. Collapse these down into 2D images by simply averaging the values at each lenslet (ignoring NANs).  Rescale Image1, then compute  diffImage = I1scaled - k* I2

**Category**:  SpectralScience      **Order**: 4.3

**Inputs**:   Datacube of ADI residuals

**Outputs**:  Datacube with simple 2-wavelength SDI subtraction

**Notes**:

.. code-block:: idl


   This recipe rescales and subtracts 2 frames in different user-defined
   bandwidths. This recipe is used for speckle suppression using the
   Marois et al (2000) algorithm.

   This routine does NOT update the data structures in memory. You **MUST**
   set the keyword SAVE=1 or else the output is silently discarded.

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
    2013-07-17 MP: Renamed for consistency
    2013-08-07 ds: idl2 compiler compatible

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


**IDL Filename**: gpi_simple_sdi_of_post_adi_residual.pro


.. index::
    single:Combine Polarization Sequence via Double Difference

.. _CombinePolarizationSequenceviaDoubleDifference:

Combine Polarization Sequence via Double Difference
---------------------------------------------------



**Category**:  PolarimetricScience,Calibration      **Order**: 4.4

**Inputs**:  Multiple polarization pair datacubes

**Outputs**:  a single Stokes datacube      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	Combine a sequence of polarized images via the SVD method, after first
	performing double differencing to remove systematics between the e- and
	o-rays.

	See James Graham's SVD algorithm document, or this algorithm may be hard to
	follow.  This is not your father's imaging polarimeter any more!



 	This routine assumes that it can read in a series of files on disk which were written by
 	the previous stage of processing.



 GEM/GPI KEYWORDS:EXPTIME,ISS_PORT,PAR_ANG,WPANGLE
 DRP KEYWORDS:CDELT3,CRPIX3,CRVAL3,CTYPE3,CUNIT3,DATAFILE,NAXISi,PC3_3





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
    IncludeSkyRotation      int           [0,1]          1                                                 1: Include, 0: Don't
                  Save      int           [0,1]          1                                1: save output on disk, 0: don't save
                 gpitv      int         [0,500]         10    1-500: choose gpitv session for displaying output, 0: no display 
======================  =======  ==============  =========  ===================================================================


**IDL Filename**: gpi_combine_polarizations_dd.pro


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
    2014-03 MP and MM-B: Polarization coordinates and angles verification and debug

**Parameters**:

======================  =======  ==============  =========  ===================================================================
                  Name     Type           Range    Default                                                          Description
======================  =======  ==============  =========  ===================================================================
             HWPoffset    float    [-360.,360.]     -29.14                  The internal offset of the HWP. If unknown set to 0
  IncludeSystemMueller      int           [0,1]          0                                                 1: Include, 0: Don't
    IncludeSkyRotation      int           [0,1]          1                                                 1: Include, 0: Don't
                  Save      int           [0,1]          1                                1: save output on disk, 0: don't save
                 gpitv      int         [0,500]         10    1-500: choose gpitv session for displaying output, 0: no display 
======================  =======  ==============  =========  ===================================================================


**IDL Filename**: gpi_combine_polarization_sequence.pro


.. index::
    single:Combine 3D Datacubes

.. _Combine3DDatacubes:

Combine 3D Datacubes
--------------------

 Combine 3D datacubes via mean or median. 

**Category**:  ALL      **Order**: 4.5

**Inputs**:  3d datacubes

**Outputs**:  a single combined datacube      **Output Suffix**:  strlowcase(method)

**Notes**:

.. code-block:: idl


  Multiple 3D cubes can be combined into one, using either a Mean or a Median.

  TODO: more advanced combination methods. Improved sigma-clipped mean implementation



 HISTORY:
 	 Jerome Maire 2008-10
   2009-09-17 JM: added DRF parameters
   2009-10-22 MDP: Created from mediancombine_darks, converted to use
   				accumulator.
   2010-01-25 MDP: Added support for multiple methods, MEAN method.
   2011-07-30 MP: Updated for multi-extension FITS
   2012-10-10 MP: Minor code cleanup
   2013-07-29 MP: Rename for consistency

**Parameters**:

==========  ======  ===============================  =========  ======================================================================
      Name    Type                            Range    Default                                                             Description
==========  ======  ===============================  =========  ======================================================================
    Method    enum    MEAN|MEDIAN|SIGMACLIP|MINIMUM     MEDIAN    How to combine images: median, mean, or mean with outlier rejection?
  sig_clip     int                             0,10          3              Clipping value to be used with SIGMACLIP in sigma (stddev)
      Save     int                            [0,1]          1                                   1: save output on disk, 0: don't save
     gpitv     int                          [0,500]          2       1-500: choose gpitv session for displaying output, 0: no display 
==========  ======  ===============================  =========  ======================================================================


**IDL Filename**: gpi_combine_3d_datacubes.pro


.. index::
    single:Quality Check Wavelength Calibration

.. _QualityCheckWavelengthCalibration:

Quality Check Wavelength Calibration
------------------------------------

 Performs a basic quality check on a wavecal based on the statistical distribution of measured inter-lenslet spacings. 

**Category**:  Calibration      **Order**: 4.5

**Inputs**:  3D wavecal

**Outputs**:  if wavecal fails quality check, then recipe is failed

**Notes**:

.. code-block:: idl


	Quality check wavelength calibration:
	 Looks for unexpected statistical anomalies or offsets in the
	 wavelength calibration, as implemented in the utility
	 function `gpi_wavecal_sanity_check`




 HISTORY:
   2013-11-28 MP: Created.

**Parameters**:

==============  ========  =================  ==========  =========================================================================================================================
          Name      Type              Range     Default                                                                                                                Description
==============  ========  =================  ==========  =========================================================================================================================
  error_action    string    [Fail|Ask_user]    Ask_user    If the quality check fails, should the recipe immediately fail or should I alert the user and ask what they want to do?
       Display       int           [-1,100]          -1                                 -1 = No display; 0 = New (unused) window; else = Window number to display diagnostic plot.
          Save       int              [0,1]           1                                                                                      1: save output on disk, 0: don't save
==============  ========  =================  ==========  =========================================================================================================================


**IDL Filename**: gpi_quality_check_wavelength_calibration.pro


.. index::
    single:Median Combine ADI datacubes

.. _MedianCombineADIdatacubes:

Median Combine ADI datacubes
----------------------------

 Median combine all residual datacubes after an ADI (or LOCI) speckle suppression.

**Category**:  SpectralScience      **Order**: 4.5

**Inputs**:  Many datacubes with ADI subtraction residuals

**Outputs**:  Median combined residual datacube      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


     Median all ADI datacubes




 HISTORY:
    Jerome Maire :- multiwavelength 2008-08
    JM: adapted for GPI-pip
   2009-09-17 JM: added DRF parameters
   2010-10-19 JM: split HISTORY keyword if necessary
   2013-07-16 MP: Rename for consistency

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]         10    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_median_combine_adi_datacubes.pro


.. index::
    single:Pad Wavelength Calibration Edges

.. _PadWavelengthCalibrationEdges:

Pad Wavelength Calibration Edges
--------------------------------

  pads the outer edges of the wavecal via extrapolation to cover lenslets whose spectra only partially fall on the detector field of view.

**Category**:  Calibration      **Order**: 4.6

**Inputs**:  3D wavecal

**Outputs**:  3D wavecal with extrapolated edges

**Notes**:

.. code-block:: idl


	This primitive extrapolates from the lenslets near the edge of the
	detector to provide estimated wavelength solutions for the 'fractional'
	lenslets, whose spectra only fall partially on the detector.

	Note that these fractional spectra are not generally going to be
	useful for scientific analyses, but for some datacube processing
	tasks such as destriping it can be helpful to have wavelength
	solutions that cover these lenslets.





 HISTORY:
   2013-11-28 MP: Created.

**Parameters**:

==================  ======  =========  =========  =====================================================================================================
              Name    Type      Range    Default                                                                                            Description
==================  ======  =========  =========  =====================================================================================================
              Save     int      [0,1]          0                                                                  1: Save output to disk, 0: Don't save
  gpitvim_dispgrid     int    [0,500]         15    1-500: choose gpitv session for displaying image output and wavcal grid overplotted, 0: no display 
==================  ======  =========  =========  =====================================================================================================


**IDL Filename**: gpi_pad_wavelength_calibration_edges.pro


.. index::
    single:Subtract Mean Stellar Polarization

.. _SubtractMeanStellarPolarization:

Subtract Mean Stellar Polarization
----------------------------------

 This description of the processing or calculation will show ; up in the Recipe Editor GUI. This is an example template for creating new ; primitives. It multiples any input cube by a constant value.

**Category**:  PolarimetricScience      **Order**: 5.0

**Inputs**:  Coronagraphic mode Stokes Datacube

**Outputs**:  That datacube with an estimated stellar polarization subtracted off.      **Output Suffix**: 'stokesdc_sub' 		 ; set this to the desired output filename suffix

**Notes**:

.. code-block:: idl


		Subtract an estimate of the stellar polarization, measured from
		the mean polarization inside the occulting spot radius.

		This primitive is simple, but has not been extensively tested.
		Under what circumstances, if any, it is useful on GPI data in practice
		is still TBD.







 HISTORY:
    2014-03-23 MP: Started

**Parameters**:

=======  ======  =========  =========  ===================================================================
   Name    Type      Range    Default                                                          Description
=======  ======  =========  =========  ===================================================================
   Save     int      [0,1]          1                                1: save output on disk, 0: don't save
  gpitv     int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
=======  ======  =========  =========  ===================================================================


**IDL Filename**: gpi_subtract_mean_stellar_polarization.pro


.. index::
    single:Insert Planet into datacube

.. _InsertPlanetintodatacube:

Insert Planet into datacube
---------------------------

 This primitive inserts planets into reduced datacubes. It can be run multiple times to insert multiple planets. 

**Category**:  SpectralScience      **Order**: 5.0

**Inputs**:  A fully reduced datacube prior to any speckle manipulation. A planet's distance, separation, position angle, mass, age, and formation scenario (hot/cold start).

**Outputs**:  The datacube with an inserted planet.      **Output Suffix**: 'wplnt' 		 ; set this to the desired output filename suffix

**Notes**:

.. code-block:: idl



 This primitive allows users to input artificial planets, based on the solar
 metalicity, hybrid cloud model, hot/cold formation scenario models of Spiegel
 and Burrows (2012) into reduced datacubes. The planet PSF is represented by an
 average of the four satellite spots. The models span the ages of 1 to 1000
 Myr, and masses of 1-15 Jupiter masses. If a user specifies parameters that do
 not represent an exact model the nearest model in age, then mass, is used.
 Currently, the intensity of the planets is determined assuming an instrument
 throughput of 18.6%, combined with a 7.9 meter primary mirror with a 1m
 secondary. The user also has the option to scale the image to represent a star
 of a user-defined magnitude. This provides the ability to simulate multiple
 observing scenarios.

 The stellar and planet properties are written to the headers. Should the user
 wish to not include the planet information, it can be bypassed by
 de-activating the write_header_info keyword.

 At the moment there is no way to determine only the star parameters and not
 insert a planet. To do this, the user should just put the planet distance to a
 large number and separation to a small number.


 Note that the inserted separation and position angle will be SLIGHTLY different
 from the user specified values - the proper values can be found in the header







 HISTORY:
    2013-07-30 PI: Created Primitive

**Parameters**:

===================  ========  ============  =========  ==================================================================================
               Name      Type         Range    Default                                                                         Description
===================  ========  ============  =========  ==================================================================================
                Age       int      [1,1000]         10                                                                Age of planet in Myr
               Mass       int        [1,15]         10                                                    Mass of planet in Jupiter masses
         model_type    string    [hot,cold]        hot                                                Hot or Cold Start formation scenario
     position_angle     float       [0,360]       45.0                               Position angle of the planet in degrees East of North
         Separation     float      [0,1800]        500                                                      Separation in milli-arcseconds
           Star_Mag     float        [-1,8]         -1    Stellar Magnitude in H band, -1 estimates stellar magnitude from satellite spots
           distance     float      [0,1000]       10.0                                                       distance to system in parsecs
  write_header_info       int         [0,1]          1               1: Write planet info to headers 0: don't write planet info to headers
               Save       int         [0,1]          1                                               1: save output on disk, 0: don't save
              gpitv       int       [0,500]          2                   1-500: choose gpitv session for displaying output, 0: no display 
===================  ========  ============  =========  ==================================================================================


**IDL Filename**: gpi_insert_planet_into_cube.pro


.. index::
    single:Save Output

.. _SaveOutput:

Save Output
-----------

 Save output to disk as a FITS file. Note that you can often do this from another module by setting the 'save=1' option; this is a redundant way to specify that. 

**Category**:  ALL      **Order**: 10.0

**Inputs**:  Any

**Outputs**:   The input is written to disk as a FITS file      **Output Suffix**: Could not be determined automatically

**Notes**:

.. code-block:: idl


	Save the current file to disk. Note that you can often do this
	from another primitive by setting the 'save=1' option; this is an
	optional, redundant way to specify that.

	Note that this uses whatever the currently defined suffix is, though you can
	also override that here.  This is the one and only routine that should be
	used to override a suffix.

  TODO: change output filename too, optionally?



 HISTORY:
	2009-07-21 Created by MDP.
   2009-09-17 JM: added DRF parameters
   2013-07-17 MP: Rename for consistency

**Parameters**:

========  ========  =========  =========  ===================================================================
    Name      Type      Range    Default                                                          Description
========  ========  =========  =========  ===================================================================
  suffix    string       None       None                                                    choose the suffix
    Save       int      [0,1]          1                                1: save output on disk, 0: don't save
   gpitv       int    [0,500]          2    1-500: choose gpitv session for displaying output, 0: no display 
========  ========  =========  =========  ===================================================================


**IDL Filename**: gpi_save_output.pro


