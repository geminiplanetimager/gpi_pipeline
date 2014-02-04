.. _configuring:

Configuring the Pipeline
=============================

The GPI data reduction pipeline relies on a variety of configuration
information. This can roughly be divided into three sections:

1. :ref:`Pipeline environment variables <config-envvars>` define some basic locations of interest in the
   file system.

2. :ref:`Pipeline configuration files <config-textfiles>`  define various options and settings. This
   follows the paradigm common to many Unix programs in that there is a
   system-wide configuration file that defines defaults, and then
   each user may optionally have a config file in their home directory to change
   values away from the defaults. In many cases, the default settings will be
   fine without being changed.
   
 
3. :ref:`Pipeline ancillary data <config-ancillarydata>` contains pipeline settings that should rarely, if ever, need to be changed (e.g. the definitions of constants such as the speed of light).
  
.. comments 
		.. note::
  		  When installing the pipeline for the first time, you will (at a minimum) need
    to set some file paths as appropriate for your site, most easily by defining environment variables as described below. 
    You may also wish to create a user settings file and
    edit its settings if you wish to change any of the defaults, but this is not
    required. 

.. _envvars:

Installing the pipeline for the first time requires several paths to be defined via
environment variables. Only three paths are explicitly required to be set; the
rest have default settings that should work for the majority of users (but may
be changed if desired).  

Automated Setup
-----------------------------------
For most users, the automated setup should be sufficient and there should be no need to configure things manually.

These installation scripts will guide you through the setup process and will automatically configure most of the settings for you. It does require you to verify/change three filepaths to ensure they point to the correct directory. 

All installation scripts are located in the pipeline/scripts directory.

.. admonition:: Mac OS and Linux

    .. image:: icon_mac2.png

    .. image:: icon_linux2.png
  
 On Mac OS and Linux, open up a terminal and go to the ``pipeline/scripts`` directory. Then you will want  to run the file ``gpi-setup-nix`` by typing in the follow command into the terminal:

 > bash gpi-setup-nix

 Follow the instructions given by the installation script. You will need to restart your terminal application for the installation to take into effect.

 If everything went well, proceed to the next section, :ref:`config-envvars`.

 If the automated setup did not work properly, you may need to install the pipeline manually: :ref:`config-manual`.

.. admonition:: Windows

    .. image:: icon_windows2.png

 For Windows Vista and newer, open up the ``pipeline/scripts`` directory and double click on ``gpi-setup-windows.bat`` to start the installation script. 

 For Windows XP users, the automated installation script will work with the following changes:
 * `Download Support Tools <http://www.microsoft.com/en-us/download/details.aspx?id=18546>'_ to install ``setx``. 
 * Edit ``gpi-setup-windows.bat``, uncomment the two lines under windows XP fix by deleting the ``::`` in front, and commenting out the lines following that use the ``where`` command and ``ERRORLEVEL`` variable by placing ``::`` in front of them.
 Alternatively, Windows XP and older users can configure the pipeline manually: :ref:`config-manual`.

 Follow the instructions given by the installation script. If everything went well, proceed to the next section, :ref:`config-envvars`.

 If the automated setup did not work properly, you may need to install the pipeline manually: :ref:`config-manual`.

.. _config-manual:

How to Set Environment Variables Manually
-----------------------------------
The pipeline includes helpful example scripts to ease the setup process, located in the ``scripts`` subdirectory of the
pipeline installation. Most users will simply want to take the example script for their selected shell and modify it for their local directory paths.

 * ``setenv_GPI_sample.bash``: Example environment variable setup script for sh or bash Unix shells
 * ``setenv_GPI_sample.csh``: Example environment variable setup script for csh or tcsh Unix shells
 * ``setenv_gpi_windows.pro``: Example setup IDL procedure for use on Windows.


The following sections walk the user through the manual pipeline configuration.

If you already know how to set environment variables on your computer, skip to :ref:`config-envvars`.

.. admonition:: Mac OS and Linux

    .. image:: icon_mac2.png

    .. image:: icon_linux2.png
  
 On Mac OS and Linux, environment variables are generally set by shell
 configuration "dot files" in your home directory.  Example shell scripts that
 set the variables required by the pipeline are provided in the
 pipeline/scripts directory. Although it is possible to edit the scripts in
 this directory, they will be overwritten when you update the pipeline.
 Therefore, the best approach is to create a local copy. Here, we walk you
 through the setup process.

 The first thing to do is determine shell you are currently using. To do so, run the following in a terminal (note that the > represents the prompt and should not be entered in the command):

 > echo $SHELL

 Depending on the output of this command, you will copy the associated setup script. The local version of the script can have a filename of your choosing.

 If using an csh shell (or varient such as tcsh), copy the setenv_GPI_sample.csh script to your home directory (``cp setenv_GPI_sample.csh ~/setenv_GPI_custom.csh``), or another suitable location if desired.
 
 If you are using an sh or bash shell, copy the setenv_GPI_sample.bash script to your home directory (``cp setenv_GPI_sample.bash ~/setenv_GPI_custom.bash``), or another suitable location if desired.

 The script file can be renamed as desired, for instance to have a leading . to make it a hidden file. 

 The next step is to ensure this script file is sourced automatically for each terminal session.

 **For bash shell users:**
  
  For users using a bash shell, modifications should be made to your .bash_profile (located in your home directory). Note that a typical install of the Mac OSX will not create the file by default. If you have not created a .bash_profile already, you must do so using your favourite text editor (note that the ``<.>`` in front of the filename means it will be hidden from standard ``ls`` commands, use ``ls -a`` to see all hidden files).
  
  Your script (e.g. setenv_GPI_custom.bash) should be sourced by inserting the following command into the .bash_profile:

  ``source ~/setenv_GPI_custom.bash``
  
  Save the script. Now each time you open a new terminal (or tab), the environment variables set above (e.g. GPI_RAW_DATA_DIR) should be set. The user should test this by typing the following command in a newly opened terminal:

  ``echo $GPI_RAW_DATA_DIR``

  If the command does not return the path you set in the script, then the .bash_profile is not being sourced, or you have an error in your script. See the :ref:`FAQ <frequently-asked-questions>` troubleshooting help.

 
 **For csh/tcsh users:**

  For users using a csh/tcsh shell, modifications should be made to your .cshrc or .tcshrc (located in your home directory). Note that a typical install of the Mac OSX will not create the file by default. If you have not created a .tcshrc (or .shrc .cshrc) already, you must do so using your favourite text editor (note that the ``<.>`` in front of the filename means it will be hidden from standard ``ls`` commands, use ``ls -a`` to see all hidden files).
  
  Your script (e.g. setenv_GPI_custom.csh) should be sourced by inserting the following command into the .tcshrc (or .shrc .cshrc) file: 

  ``source ~/setenv_GPI_custom.csh``
  
  Save the script. Now each time you open a new terminal (or tab), the environment variables set above (e.g. GPI_RAW_DATA_DIR) should be set. The user should test this by typing the following command in a newly opened terminal:

  ``echo $GPI_RAW_DATA_DIR``

  If the command does not return the path you set in the script, then the .tcshrc (or .shrc .cshrc) is not being sourced, or you have an error in your script. See the :ref:`FAQ <frequently-asked-questions>` troubleshooting help.

 Now proceed to the next section, :ref:`config-envvars`.

.. admonition:: Windows

    .. image:: icon_windows2.png

 If you **have IDL**, the best approach is to copy the sample code ``scripts\setenv_gpi_windows.pro`` to somewhere in your IDL path. Once completed, we will proceed to edit this file in the next section,  :ref:`config-envvars`.
 Environment variables can be set from within IDL, for instance, ::

   IDL> setenv,'GPI_DRP_QUEUE_DIR=E:\pipeline\drf_queue\'

 The setenv_gpi_windows.pro script uses this mechanism to set all the necessary paths. These commands must be repeated for each IDL session. You should `configure IDL to automatically run this program on startup <http://www.exelisvis.com/Support/HelpArticlesDetail/TabId/219/ArtMID/900/ArticleID/5367/How-do-I-specify-a-program-to-automatically-run-when-my-IDL-session-starts-up.aspx>`_.

 If you **do not have IDL** then environment variables can be set from the Control Panel's system settings dialog.  See `how to set environment variables in Windows <http://www.computerhope.com/issues/ch000549.htm>`_. 

 
 Using your method of choice, we will set the required environment variables in the next section, :ref:`config-envvars`.	   



.. _config-envvars:

Setting directory paths via environment variables
---------------------------------------------------
The following path variables are **required** to be defined.
Edit your shell configuration files (e.g. by editing the ``setenv_gpi_*`` script template discussed in the previous section)
to set the variables equal to your chosen installation paths. 


=====================  ====================================  ======================================
Variable                Contains                                Example
=====================  ====================================  ======================================
GPI_RAW_DATA_DIR        Default path for FITS file input        ``/home/username/gpi/rawdata``
GPI_REDUCED_DATA_DIR    Path to save output files               ``/home/username/gpi/reduced``
GPI_DRP_QUEUE_DIR       Path to queue directory                 ``/home/username/gpi/queue``
=====================  ====================================  ======================================

Note that the user must have write permissions to the ``$GPI_DRP_QUEUE_DIR`` and ``$GPI_REDUCED_DATA_DIR``. The raw data dir may be read-only.   

The following are paths are **optional** to define as environment variables. If not set explicitly, the pipeline will automatically use reasonable default values: 

======================  =======================================  ===========================================================
Variable                  Contains                                   Default Value if Not Set Explicitly
======================  =======================================  ===========================================================
GPI_DRP_DIR             Root dir of pipeline software             Determined automatically, location of
                                                                  the IDL pipeline code. Contains 
                                                                  subdirectories: backbone, config, 
                                                                  gpitv etc
GPI_DRP_CONFIG_DIR      Path to directory containing pipeline    ``$GPI_DRP_DIR/config``
                        config files and ancillary data.           
GPI_DRP_TEMPLATES_DIR   Path to recipe templates                 ``$GPI_DRP_DIR/recipe_templates``
GPI_DRP_LOG_DIR         Path to save output log files             ``$GPI_REDUCED_DATA_DIR/logs``
GPI_CALIBRATIONS_DIR    Location of Calibration Files Database    ``$GPI_REDUCED_DATA_DIR/calibrations``
GPI_RECIPE_OUTPUT_DIR   Where to save user-created Recipes        ``$GPI_REDUCED_DATA_DIR/recipes``
======================  =======================================  ===========================================================


The required paths above must be set before you can proceed, and those that will be
written to (queue, reduced, calibrations, and log) must have write permissions
for the user running the pipeline. 

 
.. _config-textfiles:

Configuration text files
-----------------------------------

As noted above, the GPI pipeline config file system is similar to many other Unix programs;
there's a system-wide config file that sets default settings, and then each
user may optionally have a file in their home directory that overrides those
settings.  

The allowable settings are listed in an :ref:`Appendix <config_settings>`. Many users will not need to adjust any of these since
the default settings should be fine for most cases; such users may wish to skip this section. 

The system default settings are stored in the file
``$GPI_DRP_DIR/config/pipeline_settings.txt`` provided with the pipeline software. 

If you wish to adjust settings, you should do so by creating a user settings file in your home directory rather than modifying
the system defaults file directly. This way your customized settings will be preserved when upgrading to a new version of the pipeline. 
You can create a user settings file just by copying the system settings file to your home directory. The location of the user config file depends on the
operating system. 

.. admonition:: Mac OS and Linux

      .. image:: icon_mac2.png

      .. image:: icon_linux2.png


    The user config file must be named ``.gpi_pipeline_settings`` located in the user's home directory. (This will be a hidden "dotfile" as is typical.)

.. admonition:: Windows

      .. image:: icon_windows2.png

    The user config file must be called ``gpi_pipeline_settings.txt`` be in the user's home directory.

.. admonition:: Note for Subversion Users

  Users installing from the Subversion repository, if you wish to change pipeline settings, you **must** create a local user config file in your
  home directory. **Do not**  modify the system default configuration file ``config/pipeline_settings.txt``. If you do
  this, whenever you update your code from subversion it could overwrite your
  configuration (and vice versa your local changes could get propagated to other users accidentally). 


**Configuration file contents:** The config file has an extremely simple plain text file format. Each line of it is just::
  SETTING_NAME <tab> SETTING_VALUE

Settings names are case insensitive. Values are all returned as strings.  Boolean
parameters are entered as 0 or 1. 


If you leave the local user config file blank or nonexistent for a given setting, the default setting from the system config will be used.  


.. note:: 
  
    In addition to being set via environment variables, the above
    directory names (e.g. GPI_CALIBRATIONS_DIR) may also be set in the configuration files (/config/gpi_pipeline_settings.txt). 
    The environment variables, if set, have higher precedence and will override the config files.  
    For historical reasons, environment variables are the preferred way to set paths (they
    are convenient for use interactively in the shell, for instance you can
    ``cd $GPI_RAW_DATA_DIR``, etc.). But, if desired for some reason, it is possible
    to set paths using just the text config files. 
      
  
 


.. _config-ancillarydata:

Ancillary data files
-----------------------------------

A handful of data files are distributed with the pipeline
in a subdirectory ``config``.  In most cases, users
will not have any need to edit any of these. They are listed here for completeness only. 

For instance, there is a file containing the orbital elements of calibration
binaries, while another file describes the wavelengths of emission lines in
the wavelength calibration lamps at Gemini. These files are provided

* **pipeline_constants.txt**: This is a text file containing various constants about the GPI instrument, Gemini South, and so on. These values are not expected to change often, if ever. The format of this file is identical to the pipeline settings file.  A full list of constants and default values is available in the :ref:`Appendix <gpi_constants>`.

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

* **filters**: This subdirectory contains the measured transmission profiles for the five GPI IFS bandpass filters.

* **pickles**: This subdirectory contains data files comprising the `Stellar Spectral Flux Atlas Libray, from Pickles (1998) <http://www.stsci.edu/hst/observatory/crds/pickles_atlas.html>`_. 

* **planet_models**: This subdirectory contains 
  model planet atmosphere spectra from `Spiegel and Burrows (2011) <http://www.astro.princeton.edu/~burrows/warmstart/index.html>`_, binned to lower resolution to match the GPI IFS.


Continue to reading about :ref:`first-startup`.




