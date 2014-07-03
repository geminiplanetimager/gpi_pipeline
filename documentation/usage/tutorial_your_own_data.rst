.. _usage-quickstart-yourdata:

Tutorial 3: Reducing your own GPI data
#####################################################

So you have your own GPI data, probably from queue observations. What's next? 





Getting your data from CADC 
=================================================

1. Go to http://www2.cadc-ccda.hia-iha.nrc-cnrc.gc.ca/cadcbin/en/gsa/archive/pi_form.pl
2. Enter the name of your program and your Phase II password.
3. Under "Proprietary Data Access", click " Search for Complete Catalogue"
4. Under "Select a standard query", select "Any" and click "Continue to query form"
5. In this new webpage, under "Science Program", enter the name of your program.


You should then be able to select and download your data files.

.. note:: 
    Right now only the raw files are being archived. We hope that by 2014B also the 
    quicklook datacubes produced at the summit will also be archived. 


Getting related calibration files from CADC 
=================================================

.. warning::
   The following describes how things are working as of 2014A. It is possible that by 2014B the archive will be producing calibration 
   packages for GPI that contain the required calibrations for just your program. 


Detailed instructions about retrieving your calibration data from CADC can be found at
`this page <http://www.gemini.edu/sciops/instruments/gpi/data-reduction-and-calibrations?q=node/12206>`_ on the Gemini website. 

For the convenience of the user, Gemini provides several pre-reduced calibrations on the `Public Data Wepage <http://www.gemini.edu/sciops/instruments/gpi/public-data>`_. A complete set of Darks and wavelength calibration files in all bands are included.



First Reduction of Your Files
===============================

The first goal is to produce your own datacubes that are reasonably well calibrated but perhaps not the best possible. So we won't worry about every little possible detaled adjustment yet. At this point we are more or less reproducing the quicklook reduction that happens at the summit. To begin, open the data reduction pipeline. You should see two windows, the GPI Launch, and the GPI DRP Status Console.

First step - Load the downloaded calibration files into the Data Parser. This should create recipes to reduce darks and wavecals or polcals depending on the mode (Spectral or Polarimetry) of your data. To begin a reduction, select a recipe and Queue using the buttons on the bottom left of the Data Parser window. 

Check that those look OK on GPItv. 

Making wavecals is a 2 step process: Generate a good high quality wavecal from deeper lamp data taken during the day at zenith, then update for the flexure of your science data based on the short exposure wavecal taken at the same time. 

For more information on reducing darks, see :ref:`Darks < processing_step_by_step_darks>`.

For more information on wavelength calibrations, see :ref:`Wavelength Calibrations <wavelength_calibration>`.


Once the calibration files are reduced and saved to your calibrations database, you are now ready to reduce the science data. Open the Recipe Editor. Load the FITS files of interest. Then in the recipe template selection, choose the reduction category (spectral or polarimetric science) and then choose the appropriate quicklook reduction template. E.g., "Quicklook Automatic Datacube Extraction".

Queue the recipe (using the Save Recipe and Queue button). It should produce some datacubes which are displayed in GPItv as they are created. 


What if something goes wrong? 
==================================

For Frequently asked questions about data reduciton, see :ref:`FAQ <frequently-asked-questions>`.

Below we've briefly listed some common issues and solutions.

 - Checkerboard or moire pattern. Indicates wavecal is offset and needs to be updated. 

 - sat spots are not found. Describe how to deal with that.  
   Sat spots are used for precise astrometry of the star behind the coronagraph, for PSF registration during subtraction. 
   Simple workaround but imprecise is to manually enter an estimated coordinates for the star. 

 - Be careful about the automatic contrast curves. May not be optimal, e.g. are biased if you look at a binary star



Further questions will be addressed on the `Gemini Data Reduction User Forum <http://drforum.gemini.edu/forums/gemini-data-reduction/>`_. We encourage all GPI users to contribute to this forum with questions, comments, and include any ideas or improvements for the GPI Data Reduction Pipeline. 
