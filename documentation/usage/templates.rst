.. _templates:

Recipe Templates
==================

Template recipes are provided for most common data processing tasks, including
analyses of calibration data and science data. In many cases, to reduce your data
you just need to select the relevant FITS files and choose which template recipe
should be applied (or, for common tasks, the :ref:`data_parser` may automatically select the right template for you). 


For convenience, template recipes are divided into several different reduction types:

* :ref:`Spectral Science <spectralscience_templates>`
* :ref:`Polarimetry Science <polarimetryscience_templates>`
* :ref:`Calibration <calibration_templates>`
* :ref:`Testing <testing_templates>`

These different types simply provide a convenient way of restricting which subset of
templates are displayed on screen to choose from, based on the recipes that are 
most likely to be of use for the data at hand. [#footnote1]_ Also, when editing a given recipe, the list of available primitives 
is optionally filtered to only display primitives appropriate for the current type of recipe. This is mostly just a convenience to keep 
spectral and polarimetry primitives from cluttering the interface unnecessarily when not in use. 


Some recipes are designed to start from raw data files and produce datacubes from each raw file and/or combined results from an entire sequence. 
Other recipes are designed to start from already-existing datacubes and just do the sequence combination. In general we recommend 
first creating datacubes only, and not trying to combine sequences right away.  Once you have datacubes you are satisfied with then you can do the 
sequence combination using the recipes that start from datacubes. The problems of creating datacubes and combining sequences for PSF subtraction are 
mostly separable, so it makes sense to consider each step one at a time and iterate on them separately.



.. _spectralscience_templates:

Spectral Science Mode Template Recipes
---------------------------------------

Here are the available recipe templates for spectral mode reductions. This list intentionally includes a wide range 
of options, and some recipes are more recommended than others. These are indicated below. 



=============================================================  ==============   =======================================================================================================
Template Name                                                  Expected Input       Purpose
=============================================================  ==============   =======================================================================================================
**Quicklook Automatic Datacube Extraction**                     Raw files       Used for real-time reductions while observing, to produce decent quality "quick look" datacubes 
                                                                                without doing the full calibration process.  
**Create Clean 2D Detector Image**                              Raw files       Cleans up detector artifacts (dark subtraction, bad pixel repair, etc) but stops before 
                                                                                making a datacube. Outputs a 2D image. 
**Simple Datacube Extraction**                                  Raw files       Create a basic datacube with the minimal amount of processing.  This is a good starting point
                                                                                for making your own first datacubes before adding additional calibration steps. 
                                                                                *Recommended*
**Calibrated Datacube Extraction**                                              Aimed at performing a better reduction including more rejection of detector artifacts, 
                                                                                flux-calibration based on satellite spots, and updates to world coordinates information.
                                                                                *Recommended*
**Contrast Measurement**                                        Raw files       Used to obtain a contrast measurement and evaluate AO performance. This same calculation 
                                                                                can also be performed using GPItv
**Simple Extraction, ADI+SSDI reduction**                       Raw files       Performs simple reduction and an ADI+SSDI reduction. 
**Simple Extraction, ADI+LOCI reduction**                       Raw files       Performs simple reduction and an ADI+LOCI reduction. 
**Rotate and combine extended object**                                          For a simple extraction and ADI reduction of extended objects
**KLIP ADI reduction (From Reduced Cubes)**                     Raw files       Starting from a series of already-reduced datacubes, combine the sequence using ADI and the
                                                                                KLIP algorithm (Soummer et al. 2012). This is a good choice for PSF subtraction since
                                                                                the KLIP algorithm is relatively fast.
                                                                                *Recommended*
**Contrast measurement (From Raw Data)**                        Raw files       Create datacubes and then use the satellite spots to measure the 
                                                                                contrast. The contrast profile will be saved to a file.
**'Contrast measurement (From Reduced Cubes)'**                 Datacubes       From a series of already-reduced datacubes, use the satellite spots to measure the
                                                                                contrast. The contrast profile will be saved to a file.
**Basic ADI + Simple SDI reduction (From Raw Data)**            Raw files       Make datacubes and then combine them using ADI and SDI for PSF 
                                                                                subtraction. This is not a recommended recipe for the reasons noted above, that it's better to
                                                                                break up reduction into smaller chunks, but this recipe still exists for historical reasons.
**Basic ADI + Simple SDI reduction (From Reduced Cubes)**       Datacubes       From already-reduced cubes, perform PSF subtraction using basic ADI and simple SDI.  This
                                                                                is an OK recipe, but the Basic ADI algorithm does not perform as well as LOCI or KLIP. 
**LOCI ADI reduction (From Raw Data)**                          Raw files       Starting from raw files, create datacubes and perform PSF subtraction using 
                                                                                LOCI (Lafreniere et al. 2007)
**LOCI ADI reduction (From Reduced Cubes)**                     Datacubes       Starting from already-reduced datacubes, perform PSF subtraction using LOCI 
                                                                                (Lafreniere et al. 2007)
                                                                                *Recommended*
**Create datacubes, Rotate, and Combine unocculted sequence**   Raw files       Starting from raw data, create datacubes, and then rotate, align, and sum them without doing
                                                                                any PSF subtraction. This is intended for observations of unocculted targets, for instance
                                                                                solar system objects. 
                                                                                *Recommended*
**KLIP SDI (From Raw Data)**                                    Raw files       Starting from raw data
=============================================================  ==============   =======================================================================================================
                                                        


.. _polarimetryscience_templates:

Polarimetry Science Mode Template Recipes
-------------------------------------------

=============================================================  ==============   =======================================================================================================
Template Name                                                  Expected Input       Purpose
=============================================================  ==============   =======================================================================================================
**Quicklook Automatic Polarimetry Extraction**                  Raw files       For real-time reductions while operating the instrument. It produces decent quality datacubes without 
                                                                                doing the full calibration process.
**Simple Polarization Datacube Extraction**                     Raw files       Performs the extraction of a polarization difference cube including dark subtraction, flexure 
                                                                                correction, noise reduction and bad pixel correction. 
                                                                                *Recommended*
**Basic Polarization Sequence  (From Raw Data)**                Raw files       Performs a basic reduction to generate a Stokes datacube. This includes all the steps in the Simple 
                                                                                Polarization Datacube Extraction, plus the least squares Mueller matrix construction of the final 
                                                                                Datacubes. 
**Basic Polarization Sequence (From podc cubes)**               Datacubes       Creates a Stokes Datacube from already reduced difference cubes. The data is rotated North up and 
                                                                                several additional noise reduction techniques are performed. 
                                                                                *Recommended*
=============================================================  ==============   =======================================================================================================




.. _calibration_templates:

Calibration Data Template Recipes
---------------------------------------

Calibration Recipes are discussed in more detail in the :ref:`Step-by-Step guide to processing data<processing_step_by_step>` sections.

=============================================================  ==============   =======================================================================================================
Template Name                                                  Expected Input       Purpose
=============================================================  ==============   =======================================================================================================
**Dark**
**Create Thermal/Sky Background Cubes**                         Raw files       Create background datacubes for subtraction from science data. This is most relevanta for K band 
**Combine Thermal/Sky Background Images**
**Generate Cold Bad Pixel Map from Flats**
**Generate Hot Bad Pixel Map from Darks**
**Combine Bad Pixel Maps**
**Find satellite locations**
**Lenslet scale and orientation**
**Flat-field Extraction**
**Wavelength Solution**
**Wavelength Solution 2D**
**Quick Wavelength Solution**
**Create Polarized Flat-field**
**Calibrate Polarization Spots Locations**
**Calibrate Polarization Spots Locations - Parallel**
=============================================================  ==============   =======================================================================================================




.. _testing_templates:

Software Testing Template Recipes
---------------------------------------

This is a section for template recipes that are used in testing and debugging
the pipeline itself. There are several recipes of this type. Don't try to use these for science reductions directly.

.. rubric:: Footnotes

.. [#footnote1] But that said, there is nothing stopping you from choosing to apply a 
                Calibration type template to your science data, or vice versa, if 
                for some reason you wish to do so.  

