.. _configuring:

Configuring the Pipeline
=============================



The GPI data reduction pipeline relies on a variety of configuration
information. This can roughly be divided into three categories:

1. :ref:`Environment variables <config-envvars>` that define some basic locations of interest in the
   file system. For instance, the variable ``$GPI_RAW_DATA_DIR`` defines where the pipeline should look for new raw data
   files, while ``$GPI_DRP_QUEUE_DIR`` defines the queue
   directory that is watched for new reduction recipes to execute.

2. :ref:`config-textfiles` that define various options and settings. This
   follows the paradigm common to many Unix programs in that there is a
   system-wide configuration file that defines defaults, and then
   each user may optionally have a config file in their home directory to change
   values away from the defaults. In many cases, the default settings will be
   adequate without being changed.
   
 
3. :ref:`config-ancillarydata` that should rarely, if ever, need to be changed.
   For instance, there is a file containing the orbital elements of calibration
   binaries, while another file describes the wavelengths of emission lines in
   the wavelength calibration lamps at Gemini. These files are provided
   with the pipeline code in a subdirectory ``config``. 

.. note::
    When installing the pipeline for the first time, you will (at a minimum) need
    to set some file paths as appropriate for your site, most easily by defining
    environment variables as described below. 

    You may also wish to create a user settings file and
    edit its settings if you wish to change any of the defaults, but this is not
    required. 

After you have configured your desired settings as described below, proceed to  :ref:`first-startup`.

.. _config-envvars:

Environment variables to set directory paths
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Pipeline operation requires several paths to be defined. Only a few paths are
explicitly required to be set; the rest have default settings that should work
for the majority of users (but may be changed if desired). To ease this setup
process, there are sample shell scripts
``setenv_GPI_sample.{csh/bash}`` in the ``pipeline/scripts`` subdirectory that
demonstrate how to set up your environment for Unix and Mac OS systems.  An IDL
program is also included for Windows users. 




The path variables that are **required** are:
 

=====================  ====================================  ======================================
Variable                Contains                                Example
=====================  ====================================  ======================================
GPI_RAW_DATA_DIR        Default path for FITS file input        ``/some/network/disk/gpi/rawdata``
GPI_REDUCED_DATA_DIR    Path to save output files               ``/some/network/disk/gpi/reduced``
GPI_DRP_QUEUE_DIR       Path to queue directory                 ``/home/username/gpi/queue``
=====================  ====================================  ======================================

.. comment
   DRP_DIR was listed as one of the required paths *and* as one of the optional ones. I think that
   it is probably optional at this point?
   GPI_DRP_DIR             Path to DRP IDL code                    ``/home/username/IDL/gpi/pipeline``
  
Note that the user must have write permissions to the ``$GPI_DRP_QUEUE_DIR``
and ``$GPI_REDUCED_DATA_DIR``. The raw data dir may be read-only.   


.. admonition:: Note to GPI Instrument Team 

    For GPI instrument team members who are pulling data directly
    from VOSpace cloud storage, make sure that your Reduced and Queue directories are set to local paths, and
    do not point to the mounted VOSpace.  Not only would that result in overwriting other team member's reductions, 
    the VOspace is much, much slower than local disk. See the setenv_GPI_sample files for more
    details.

The additional path settings are as follows:


=======================   ======================================   ======================================================================
Variable                  Contains                                 Default Value if Not Set Explicitly
=======================   ======================================   ======================================================================
GPI_DRP_DIR               Root dir of pipeline software             (Determined automatically as the location of the IDL pipeline code.)
GPI_DRP_CONFIG_DIR        Path to directory containing pipeline     ``$GPI_DRP_DIR/config``
                          config files and ancillary data.           
GPI_DRP_TEMPLATES_DIR     Path to recipe templates                  ``$GPI_DRP_DIR/recipe_templates``
GPI_DRP_LOG_DIR           Path to save output log files             ``$GPI_REDUCED_DATA/logs``
GPI_CALIBRATIONS_DIR      Location of Calibration Files Database    ``$GPI_REDUCED_DATA/calibrations``
GPI_RECIPE_OUTPUT_DIR     Where to save user-created Recipes        ``$GPI_REDUCED_DATA/recipes``
=======================   ======================================   ======================================================================

Note for users who checkedout the pipeline from the SVN respository. The GPI_DRP_DIR variable should point to the pipeline directory **inside** the directory where the files where checked out as described in :ref:`Installing from the Source Code Repository <installing-from-repos>`.

If valid environment variables are not found during pipeline startup, a dialog
will be displayed to alert the user of this fact. The required paths must be
set before you can proceed. 

Also note that all directories must actually exist, and those that will be
written to (queue, reduced, calibrations, and log) must have write permissions
for the user running the pipeline.

.. _envvars:

How to Set Environment Variables
-----------------------------------

.. admonition:: Mac OS and Linux

    .. image:: icon_mac2.png

    .. image:: icon_linux2.png
  
  On Mac OS and Linux, the best approach is probably to make a copy of
  ``setenv_GPI_sample.{csh/bash}`` in your home directory, edit the copied file to
  set paths as desired for your machine, and then add a line to your shell
  startup file to source that edited file in the usual manner.  (e.g. ``source
  ~/setenv_GPI_config.csh```)
  
  Environment variables are set in the typical manner::
  
    (t)csh:   > setenv GPI_DRP_QUEUE_DIR ~/GPI/pipeline/drf_queue       
    bash:     > export GPI_DRP_QUEUE_DIR="~/GPI/pipeline/drf_queue"
  
  To find out which shell you are currently using run: ::
    
    > echo $SHELL

  The same command allows you to check the values of all environment variables (i.e., ``echo $GPI_DRP_QUEUE_DIR``).

.. admonition:: Windows

    .. image:: icon_windows2.png
  
  On Windows, environment variables can be set from the Control Panel's system settings dialog.  See `how to set environment variables in Windows <http://www.computerhope.com/issues/ch000549.htm>`_.

  Environment variables can also be set from within IDL. For instance, ::

     IDL> setenv,'GPI_DRP_QUEUE_DIR=E:\pipeline\drf_queue\'

  If you have IDL, a simple 
  approach is to copy the sample code ``scripts\setenv_gpi_windows.pro`` to somewhere in
  your IDL path.  Edit the script as necessary, and then add it to your IDL
  startup file. 
  
  
 
.. _config-textfiles:

Configuration text files
^^^^^^^^^^^^^^^^^^^^^^^^^^^

As noted above, the config file system is similar to many other Unix programs:
there's a system-wide config file that sets default settings, and then each
user may optionally have a file in their home directory that overrides those
settings. System default settings are stored in the file
``$GPI_DRP_DIR/config/pipeline_settings.txt`` provided with the pipeline software. 

To change any of the
values from those defaults, users 
may copy that file to their home directory and 
edit individual settings as desired. ::  

     cp $GPI_DRP_DIR/config/pipeline_settings.txt ~/.gpi_pipeline_settings
     emacs (or vim, etc) ~/.gpi_pipeline_settings

If you leave the user config file
blank or nonexistent, the default settings from the system config will be used.  
(Alternatively, if you're the only user on your
machine, you could just edit the pipeline_settings.txt file too,
instead of creating a per-user config file.) 

.. admonition:: Note for Subversion Users

  If you have installed from the Subversion repository, don't  modify the
  system default configuration file ``config/pipeline_settings.txt``. If you did
  that, whenever you updated your code from subversion it could overwrite your
  configuration.  Instead, make changes to a local user config file in your
  home directory.

The location of the user config file depends on the operating system.

.. admonition:: Mac OS and Linux

      .. image:: icon_mac2.png

      .. image:: icon_linux2.png


    The user config file is ``~/.gpi_pipeline_settings``

.. admonition:: Windows

      .. image:: icon_windows2.png

    The user config file is ``gpi_pipeline_settings.txt`` in the user's home directory.




**Configuration file contents:** The config file has an extremely simple plain text file format. Each line of it is just::
  SETTING_NAME <tab> SETTING_VALUE

Settings names are case insensitive. Values are all returned as strings.  Boolean
parameters are entered as 0 or 1. 



The allowable settings are listed in an :ref:`Appendix <config_settings>`. Many users will not need to adjust any of these. All pipeline settings are retrieved using function ``gpi_get_settings``, with any entires in the user config file taking precedence over those in the system config file.

.. note:: 
  
    In addition to being set via environment variables, the above
    directory names may also be set in the configuration files. 
    The environment variables, if set, have higher precedence and will override the config files.  
    For historical reasons, environment variables are the preferred way to set paths (they
    are convenient for use interactively in the shell, for instance you can
    ``cd $GPI_RAW_DATA_DIR``, etc.). But, if desired for some reason, it is possible
    to set paths using just the text config files. 
      
  

.. _config-ancillarydata:

Ancillary data files
^^^^^^^^^^^^^^^^^^^^^

In addition to the system-wide configuration file, there is also a system-wide constants file containing
physical constants and other (mostly) static values related to GPI.  The file is located at ``$GPI_DRP_DIR/config/pipeline_constants.txt`` and is formatted in the same way as the config file.  All constants are retrieved using function ``gpi_get_contants``.  A full list of constants and default values is available in the :ref:`Appendix <gpi_constants>`.

.. note::

    As these values are not expected to change (other than very infrequently) there is no support for a user constants file.  Any changes to these values must be made in the system wide constants file.


A handful of data files are distributed with the pipeline. In most cases, users
will not have any need to edit any of these. They are listed here for completeness only. 


* **gpi_pipeline_primitives.xml**: This file is an index of all available pipeline primitives. It is 
  generated automatically by pipeline development scripts; see the Developer's Guide.

* **ifs_cooldown_history.txt**: This text file lists dates when the GPI IFS was warmed
  up for maintenance or other activities. It is used by the Calibration Database to
  help decide which calibration files are most appopriate for reducing a given set of science data
  (In general, calibration files from a different cooldown are probably not optimal.)

* **keywordconfig.txt**: This file lists the nominal header keywords in GPI-produced 
  FITS files, and whether they are expected to be found in the primary HDU or an 
  image extension HDU.

* **lampemissionlines.txt**: This is a list of xenon and argon emission line wavelengths
  used in spectral calibration.

* **orb6orbits.txt**: This is a list of calibration binary orbital parameters, taken from
  the Washington Double Star Catalog's list of suggested calibration binaries. It is used
  in astrometric calibration.

* **trans_16_15.dat**: This is a model of atmospheric transmission vs wavelength, used in some
  optional routines for calibrating telluric throughput.

* **xlocs.fits** and **ylocs.fits**: are lenslet X and Y pixel coordinate lists for the 
  mostly unsupported non-dispersed engineering mode.


* **apodizer_spec.txt**: Table of GPI apodizers and their empirically determined satellite spot flux ratios.


Additional Configuration Options
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

On some Mac OS and Linux computers, you will have display issues with the default IDL display configurations.  This will generate a repeated message in your IDL session saying something like: ::

    % X windows protocol error: BadMatch (invalid parameter attributes).

In order to correct this, you can execute the following commands in the IDL session:

.. code-block:: idl 

    IDL> device, decompose=0
    IDL> device, retain=2

If you want these commands to be executed in all IDL sessions automatically, you can add them to your IDL startup file (this is an IDL script that is run on startup of any new IDL session).  The startup file is identified by the environment variable ``$IDL_STARTUP`` (see :ref:`envvars`).

Continue to reading about :ref:`first-startup`.


