
.. _logging:

Logging and History records
################################

To ensure scientific reproducibility and aid in comparisons of results, the GPI data pipeline carefully logs its actions. 

**Log files:**
The GPI data pipeline writes a log of all activities to text files in the ``$GPI_DRP_LOG_DIR`` directory. 
A new file is created for each date, with filenames following the format ``gpi_drp_YYMMDD.log`` where ``YYMMDD`` gives the current year, month, and date 
numbers in standard Gemini fashion.  Log messages are also viewable on screen in the Status Console GUI, and printed to the console in the Pipeline IDL session.


**FITS header history:** Provenance information is also written to FITS headers of all output files, in several forms. 

 1.  A copy of the entire reduction recipe used to reduce a given file is pasted into the header, in a block of COMMENT lines. This block
     also includes comments giving the values of any environment variables used in that recipe. If an output file from one recipe is then used as 
     input to a subsequent recipe, then both recipes will be recorded in the headers cumulatively.
 2.  HISTORY lines in the FITS headers record actions as each recipe is processed, including which primitives are run and what the results are
     of various calculations. For each Primitive used in the recipe, a HISTORY line
     states the specific revision id of that primitive.  HISTORY keywords also record the date and time of reduction, the 
     computer hostname, and the username of the pipeline user. 
 3.  Some values of particular interest such as the names of calibration files used to reduce a given data set are also written as
     additional header keywords. For instance the keyword DRPWVCLF (DRP Wavecal File) records the name of the wavelength calibration file
     used when reducing a given observation.  
     

.. warning::
    Of particular note, the keyword ``QUIKLOOK = T`` indicates that a given file
    is the result of a "quicklook" quality reduction, typically in real time at the
    telescope. These may not have made use of optimal calibration files, are not
    likely to be as good as more careful re-analyses, and should
    generally not be used directly for publications.
