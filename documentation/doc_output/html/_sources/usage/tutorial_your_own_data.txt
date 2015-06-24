.. _usage-quickstart-yourdata:

Tutorial 3: Reducing your own GPI data
#####################################################

So you have your own GPI data, probably from queue observations. What's next? 





Getting your data from CADC 
=================================================

1. Go to http://www2.cadc-ccda.hia-iha.nrc-cnrc.gc.ca/cadcbin/en/gsa/archive/pi_form.pl
2. Enter the name of your program and your Phase II password.
3. Under "Proprietary Data Access", click "Search for Complete Catalogue"
4. Under "Select a standard query", select "Any" and click "Continue to query form"
5. In this new webpage, under "Science Program", enter the name of your program.


You should then be able to select and download your data files.

.. note:: 
    Right now only the raw files are being archived. We hope that by 2014B also the 
    quicklook datacubes produced at the summit will also be archived. 


Getting related calibration files
=================================================

.. warning::
   The following describes how things are working as of 2014A. It is possible that by 2014B the archive will be producing calibration 
   packages for GPI that contain the required calibrations for just your program. 


Detailed instructions about retrieving your calibration data from CADC can be found at
`this page <http://www.gemini.edu/sciops/instruments/gpi/data-reduction-and-calibrations?q=node/12206>`_ on the Gemini website. 

For the convenience of the user, Gemini provides several pre-reduced calibrations on the `Public Data Wepage <http://www.gemini.edu/sciops/instruments/gpi/public-data>`_. A complete set of Darks and wavelength calibration files in all bands are included.


.. note:: 
        **We strongly recommend all new users download those Darks and Wavecals ZIP files from the GPI public data page. It's easier to use these as a starting point rather than trying to bootstrap up a pipeline install completely from scratch.  Furthermore, the Tutorial zip file contains some additional calibration files, so if you for some reason haven't done Tutorial 1, you should at least download and install the calibration files provided there.**



First Reduction of Your Files
===============================

The first goal is to produce your own datacubes that are reasonably well calibrated but perhaps not the best possible. So we won't worry about every little possible detailed adjustment yet. At this point we are more or less reproducing the quicklook reduction that happens at the summit. To begin, open the data reduction pipeline. You should see two windows, the GPI :ref:`Launcher <launcher>`, and the GPI DRP :ref:`Status Console <status_console>`.

First step: Use the Launcher to start the :ref:`data_parser`. Load the downloaded calibration files into the Data Parser. This should create recipes to reduce darks and wavecals or polcals depending on the mode (Spectral or Polarimetry) of your data. To begin a reduction, select a recipe and Queue using the buttons on the bottom left of the Data Parser window. 

Check that the results look OK on GPItv. 

For more information on reducing darks, see :ref:`Darks <processing_step_by_step_darks>`.

Making wavecals is a 2 step process: Generate a good high quality wavecal from deeper lamp data taken during the day at zenith, then update for the flexure of your science data based on the short exposure wavecal taken at the same time. The deep wavecal does not need to be from particularly close in time to your science observations; the update for flexure does. 

For more information on wavelength calibrations, see :ref:`Wavelength Calibrations <wavelength_calibration>`.


Once the calibration files are reduced and saved to your calibrations database, you are now ready to reduce the science data. Open the :ref:`recipe_editor`. Load the FITS files of interest. Then in the recipe template selection, choose the reduction category (spectral or polarimetric science) and then choose the appropriate quicklook reduction template. E.g., "Quicklook Automatic Datacube Extraction".

Queue the recipe (using the Save Recipe and Queue button). It should produce some datacubes which are displayed in GPItv as they are created. 

There are many primitives available in the GPI Data Reduction Pipeline for additional calibrations. The complete list of all primitives is :ref:`available here <primitives>`. There is also a list of available :ref:`templates`.

Next Steps
===================

Most GPI users will want to do some form of PSF subtraction. The pipeline provides several choices for different PSF subtraction routines you can run on datacubes, including LOCI ADI, KLIP ADI and SDI, differential polarimetry, etc. There are recipe templates for these starting from either raw files or precomputed cubes. If you've made decent cubes using the above steps, you can use e.g. the "KLIP ADI Reduction (from Reduced Cubes)" recipe.  

How to optimize PSF subtractions is beyond the scope of this documentation; consult the research literature...


After you have created cubes and done some PSF subtraction, now depending on your results, you may wish to return to earlier steps of the process and iterate to adjust things. For instance you could choose to apply additional calibration to your datacubes based on a photometric standard star, add in a step for sky subtraction, and so on. 



What if something goes wrong? 
==================================

For examples of oddities you might encounter in your data, see :ref:`ifs_data_gallery`.


Below we've briefly listed some common issues and solutions.
For more Frequently Asked Questions about data reduction, see :ref:`FAQ <frequently-asked-questions>`.

 - **Checkerboard or moire pattern**. Indicates wavecal is offset due to flexure and needs to be updated. Be sure to use a wavelength calibration file created using an arc lamp taken at the same elevation as your science target. Alternatively, you can manually input the shifts due to flexure using the "Update Spot Shifts for Flexure" primitive by selecting Manual for the method and updating the manual_dx and manual_dy keywords.

 - **Satellite spots cannot be found automatically**. Satellite spots are used for precise astrometry of the star behind the coronagraph, for PSF registration during subtraction. 
   If the pipeline is not able to locate the sat spots automatically, the user can input the locations manually. In the primitive called "Measure satellite spot locations", select loc_input = 1 and then define x1,y1,x2,y2,x3,y3,x4 and y4 by looking at one of the \*_spdc FITS files with GPItv.


 - If you use a recipe that includes the 'Measure contrast' primitive, be careful about the automatic contrast curves. These may not be optimal depending on context, e.g. they're biased if you look at a binary star.



Further questions will be addressed on the `Gemini Data Reduction User Forum <http://drforum.gemini.edu/forums/gemini-data-reduction/>`_. We encourage all GPI users to contribute to this forum with questions, comments, and include any ideas or improvements for the GPI Data Reduction Pipeline. 
