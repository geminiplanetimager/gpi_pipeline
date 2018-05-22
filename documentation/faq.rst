.. _frequently-asked-questions:

.. _faq:


Frequently Asked Questions
=============================


 * :ref:`faq_installation`
 * :ref:`faq_data_reduction`
 * :ref:`faq_errors`
 * :ref:`faq_less_common`
 * :ref:`faq_gpitv`
 

.. _faq_installation:

Installation
^^^^^^^^^^^^^^^^^^^^^^^^^

When running `gpi-pipeline` it says, "gpi-pipeline: Command not found"
------------------------------------------------------------------------
This indicates that the ``pipeline/scripts`` directory has not been added to the ``$PATH``. There are a couple possible reasons for this:

1. The script that sets your environment variables (e.g. ``~/.gpienv`` file ) has not been sourced. This should generally be sourced
   from your ``.tcshrc`` or ``.bash_profile`` script located in the home directory.
   Details can be found :ref:`here<configuring>`. Remember to open a new
   terminal after modifying any shell scripts to ensure they are properly
   loaded.
2. The shell script (e.g. ``~/.gpienv`` file) has
   an error in the line that modifies the ``$PATH``. Check to make sure the
   pipeline/scripts directory is properly inserted. The users can check if the
   directory is in the path by typing ``echo $PATH`` from a shell prompt. We
   recommend you copy and paste in the pipeline/scripts output to make sure the
   directory exists. Remember that paths are case sensitive.


When trying to start the pipeline, I get the error "xterm: Can't execvp idl: No such file or directory"
----------------------------------------------------------------------------------------------------------
This cryptic message means that you are trying to start the gpi-pipeline script without having the idl executable
in your path. Perhaps you have it aliased instead, but that's not detected by the gpi-pipeline starter script. 
You can either (1) just start IDL manually via however you usually start it, and then run the ``gpi_launch_pipeline``
and ``gpi_launch_guis`` commands; (2) change your ``$PATH`` to include the directory with idl, (3) put a symlink pointing to idl in some
directory already in your path, or (4) edit your local copy of the ``gpi-pipeline`` script to explicitly set the full
path to the idl executable. 

If you are using the compiled IDL runtime version of the pipeline, note that a copy of the IDL runtime is included in
the 'idl81/bin/' directory included with the pipeline. 


I get an "X windows protocol error" repeatedly. What's up?
--------------------------------------------------------------

On some Mac OS and Linux computers, you may have display issues with the default IDL display configurations.  This will generate a repeated message in your IDL session saying something like: ::

    % X windows protocol error: BadMatch (invalid parameter attributes).

In order to correct this, you can execute the following commands in the IDL session:

.. code-block:: idl 

    IDL> device, decompose=0
    IDL> device, retain=2

If you want these commands to be executed in all IDL sessions automatically, you can add them to your IDL startup file (this is an IDL script that is run on startup of any new IDL session).  The startup file is identified by the environment variable ``$IDL_STARTUP`` (see :ref:`config-envvars`).


On a Mac, I tried to start the compiled pipeline by double clicking the .sav files, but I got a cryptic error about not being able to find a pipeline config file
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
On Mac OS, unfortunately if you define environment variables in your shell config files, those only apply to Terminal and X11 sessions. If you try to start something from the Finder
your environment variables won't be defined in the child process. The fix is to start the pipeline from the command line in a shell (Terminal or xterm), for instance by using the ``gpi-pipeline`` script that is provided. Don't try to start it just by double clicking from Finder. 


On my Mac, the GUI windows pop up with their title bars hidden under the Mac OS menu bar, so I can't move them around or see the very top of them. Why, and how do I stop this?
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
This appears to be due to a bug in X11 on Macs running Mavericks with multi-monitor support. See `this discussion at Stackexchange <http://apple.stackexchange.com/questions/111465/is-there-a-way-to-move-a-window-without-the-mouse>`_. The workaround is to turn off the feature that displays the Mac OS menu bar on all monitors. Sorry, this is an Apple problem we can't do anything about!




.. _faq_data_reduction:

Data Reduction Questions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

For guidance on data reduction, please consult the :ref:`ifs-data-handbook`.

What pre-reduced calibration files are available for download?
------------------------------------------------------------------

See `this discussion at the Gemini Data Reduction Forum <http://drforum.gemini.edu/topic/gpi-wavelength-calibration/>`_.

Some reduced calibration files are available from the Gemini `GPI Public Data <http://www.gemini.edu/sciops/instruments/gpi/public-data>`_ page.

There are also files available in the :ref:`tutorial <usage-quickstart>` data sets.


The GPI pipeline crashes when trying to do the wavelength calibration with error:  error in starting GPI_LOAD_WAVELENGTH_CALIBRATION: calibration file  -1 not found.
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

This most likely is due to missing calibration files. To check if the files are being correctly seen within the code, press the "Rescan Calib. DB" on the GPI GUI. This will re-index all the available calibration files.


The satellite spots cannot be found in my coronagraphic data. What should I do?
--------------------------------------------------------------------------------

See the `discussion at the Gemini Data Reduction Forum <http://drforum.gemini.edu/topic/gpi-satellite-spot-not-found/>`_.

How do I de-rotate my data to have north up and east left?
-------------------------------------------------------------------

See :ref:`this part of the Data Handbook <ifs_fov_rotate>`.

Hey, what's this weird thing in my data?  Can I see some examples of known artifacts and systematics I might encounter? 
----------------------------------------------------------------------------------------------------------------------------

Yes, yes you can. See :ref:`this gallery of example data and occasional artifacts <ifs_data_gallery>`.


.. _faq_errors:

Common pipeline software issues
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Why did the pipeline stop and return to a prompt in the middle of my reduction?
----------------------------------------------------------------------------------
This is most likely an IDL_PATH issue. See 'How do I diagnose an IDL_PATH error?'
 
How do I diagnose an IDL_PATH error?
----------------------------------------------------------
The user should check to make sure that the proper dependency is being called. For example, if the pipeline crashes in a function called APER (which is part of the IDL astrolib library). The user should issue the command:

.. code-block:: idl 

    IDL> which, aper

Doing this will show each aper.pro file that is in the ``$IDL_PATH``, the one that is in the pipeline directory should be the first on the list. If it is not, then the pipeline directory does not have the priority when calling this function. To correct this, ensure that the pipeline directory comes before the other directories in your IDL path by setting the ``$IDL_PATH`` in your setup script (or wherever you set the ``$IDL_PATH variable``) as follows:

For sh/csh/tcsh shells - ``setenv IDL_PATH "+/home/labuser1/GPI/pipeline:${IDL_PATH}"``

For bash shells - ``export IDL_PATH="+/home/labuser1/GPI/pipeline/${IDL_PATH}"``

If the which command is not defined, this means that the pipeline and external directories have not been added to the $IDL_PATH. Verify that the modifications to the $IDL_PATH in the environment variable configuration scripts (e.g. setenv_GPI_sample.csh or setenv_GPI_sample.bash) is correct.


Variable is undefined: STR_SEP.
--------------------------------
For users having IDL 8.2+, the str_sep.pro program is now an obsolete command. Although no pipeline source code calls this function, it is still used in some other external dependencies. For the time being, users should add the `idl/lib/obsolete` folder to their `$IDL_PATH` to remedy this issue. This can be done in the last line of the configuration scripts (e.g `setenv_GPI_custom.csh` or `setenv_GPI_custom.bash` - as discussed :ref:`here <configuring>`)



Mac OSX Time machine warnings about permissions 
----------------------------------------------------
Mac OSX Lion and Mountain Lion users running IDL 8.2 have been known to see the following error:

``2011-07-21 12:12:39.649 idl[11368:1603] This process is attempting to exclude an item from Time Machine by path without administrator privileges. This is not supported.``

Although a nuisance, this error should have no affect on pipeline operation. Possible workarounds exist; details can be found `here <http://www.exelisvis.com/Support/HelpArticlesDetail/TabId/219/ArtMID/900/ArticleID/5251/5251.aspx>`_


When I try to start the pipeline, IDL crashes and says 'Error: attempt to add non-widget child "dsm" to parent "idl" which supports only widgets'. Why? :
----------------------------------------------------------------------------------------------------------------------------------------------------------

This is a `known bug in IDL <http://www.harrisgeospatial.com/Support/HelpArticlesDetail/TabId/219/ArtMID/900/ArticleID/14944/XQuartz-2710-is-Not-Compatible-with-ENVI-531-and-IDL-851.aspx>`_ where version 8.5.1 is not compatible with the most recent XQuartz 2.7.10 or newer. 
You can work around this by upgrading IDL to 8.6, downgrading XQuartz to 2.7.9, or updating the DYLD_LIBRARY_PATH environment variable as described on that bug report page, or by `moving around some X11 internal files as described here <http://www.physics.uci.edu/~barth/atv/about.html#bugs>`.


.. _faq_less_common:

Less common software issues
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


I'm trying to reduce data from multiple different days in one recipe, and the output directory is behaving unexpectedly. What's going on?
-------------------------------------------------------------------------------------------------------------------------------------------


The output directory for a recipe is set once when the recipe is loaded in, not individually for each file. Thus all output files from a 
recipe should be output to the same directory. (The one exception to this is of course reduced calibration files which are always written to the
calibration database directory.)

If the output directory is set to 'AUTOMATIC' and ``organize_reduced_data_by_dates`` is set to 1 (true), then the output directory is determined based on
the YYMMDD date string for the first FITS file in that recipe. 


I've gotten an error that the pipeline could not open its log file. What's going on?
-----------------------------------------------------------------------------------------

This error might look something like the following::

    ERROR in OPENLOG:
    could not open file /Users/username/Documents/Projects/gpi_reduced/logs/gpi_drp_150121.log
    Please check your path settings and try restarting the pipeline.


One possibility is that your disk is actually full or otherwise unwriteable (or your network file server is down, etc).

The other possibility is that your computer is having trouble connecting to a
network IDL license manager, if it's configured to use one. In such cases, if
IDL can't get a license, it will still start, but in *demo mode* -- in which case
it does not have permissions to write any files.  You'll need to fix your IDL
licensing issues before continuing (or install the compiled version of the
pipeline!).


I'm seeing a cryptic error about "ERROR: could not get a lock on the inter-IDL queue semaphore after 10 tries." What does this mean and how can I fix it? 
---------------------------------------------------------------------------------------------------------------------------------------------------------------


The full error message looks like::

        ERROR: could not get a lock on the inter-IDL queue semaphore after 10 tries.
               Failed to queue command gpitv, 'something_or_other.fits'
        If the lock on the inter-IDL queue is not being released properly, 
        use the pipeline setting launcher_force_semaphore_name to pick a different lock.


The GPI pipeline uses 2 different IDL sessions: one for the actual execution of reduction recipes, and one for running the GUIs like GPITV. These send messages back and forth to each other using shared
memory and a Unix semaphore for interprocess communication. Sometimes, for reasons that are unclear, when you restart the pipeline it cannot get a write lock to the default semaphore file name. Exactly why this
happens is frustratingly unclear, but we think has to do with some past IDL session not properly releasing the handle even after the process has exited. The exact details remain murky, hidden deep under layers
of Unix arcana. 

In any case there is an easy work around: just tell the pipeline to use some other semaphore name for communicating between the two IDL sessions. Edit your :ref:`config-textfiles` user config file (probably named ``~/.gpi_pipeline_settings`` in your home directory) to specify some other semaphore name by invoking the setting mentioned in the error message::

        launcher_force_semaphore_name   Type_pretty_much_any_arbitrary_string_here

Type, well, pretty much anything you want there for the second part. Then restart the pipeline and the error should be cleared. 

For some reason, this problem seems to crop up more often on the Gemini summit computers than anywhere else. (?!?)

 


.. _faq_gpitv:

GPItv
^^^^^^^^^


Blinking images doesn't work properly
--------------------------------------

On some X windows systems (Mac OS and Linux), the tvrd() function used to implement 
image blinking doesn't work properly. See this 
`article from Exelis <http://www.exelisvis.com/docs/TVRD.html#dg_routines_3604229493_888970>`_ 
describing the problem. 

The fix is simple: make sure that you set 

.. code-block:: idl 

    device, retain=2

in your `.idlstartup` file. 


GPITV is crashing on startup, and/or colors are behaving weirdly.
---------------------------------------------------------------------

GPItv requires a 24-bit (millions of colors) display. Check if your X11 or other graphics system settings are for some reason set to 8-bit (256 color) mode. If so, you should change them to 24 bit color before running the GPI pipeline. 




