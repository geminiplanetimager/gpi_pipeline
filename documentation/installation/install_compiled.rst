.. _installing-from-compiled:

Installing Compiled Executables for use with the IDL Runtime
==============================================================

If you do not have an IDL license, the GPI Data Reduction Pipeline is 
distributed as compiled code along with the IDL runtime. 

.. note::
        If you *do* have an IDL license, there's nothing stopping you from
        installing these compiled versions of the code instead of the source if you want
        to; it's just not required! 

  

.. _executables:

Obtaining and installing the GPI DRP Executables
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The distribution ZIP files for the GPI pipeline come in two flavors:

 * A platform-independent ZIP file containing only the compiled pipeline code itself. To use this file, you must
   download and install the IDL runtime virtual machine yourself. It may be obtained from `Excelis <http://www.exelisvis.com/ProductsServices/IDL.aspx>`_.
 * Platform specific ZIP files that contain the compiled pipeline code *plus* the IDL runtime virtual machine for a given operating system.
   These contain everything you will need to start the GPI pipeline on that OS.

**Version 1.2.1** (2014 Dec 2): 
 * `gpi_pipeline_1.2.1_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.1_compiled.zip>`_ -  GPI pipeline compiled code only
 * `gpi_pipeline_1.2.1_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.1_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
 * `gpi_pipeline_1.2.1_runtime_linux.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.1_runtime_linux.zip>`_ - GPI pipeline compiled code plus IDL runtime for Linux
 * `gpi_pipeline_1.2.1_runtime_windows.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.1_runtime_windows.zip>`_ - GPI pipeline compiled code plus IDL runtime for Windows
 * `gpi_pipeline_1.2.1_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.1_source.zip>`_ -  GPI pipeline source code (available for reference)




Obtain the desired zip file and uncompress it to a directory of your choosing. Remember this path for use when configuring DRP paths in the next section.

:ref:`priorversions` can be found below if desired

Initial Configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Before you can start the pipeline, you will need to do some basic configuration to set up your environment. There is a script to automate this process. The following is an abbreviated version of the full set of configuration options described in :ref:`configuring`.

.. admonition:: Mac OS X, Linux

      .. image:: icon_mac2.png
      .. image:: icon_linux2.png

   After downloading and unzipping, set up your shell for the pipeline. To do so, enter the following command (in which you should update the pipeline version number, 1.2.0_r3401, with the version you downloaded, and replace "[Location of the pipeline]" with the path to where-ever you unzipped that file.) ::

        unix% cd [Location of the pipeline]/gpi_pipeline_1.2.0_r3401/scripts/
	unix% ./gpi-setup-nix

   This will set up most of what's needed in the file ``.gpienv`` (in your home directory). As of version 1.2.1, this script should properly set paths for the runtime copy of IDL included with the pipeline. 
   Remember to restart your terminal for these changes to go into effect.

   For bash users, some operating systems use login shells. Run the command ``shopt login_shell`` to check whether you are using a login shell. If you are using one, you will need to source your ``.bashrc`` file into your ``.bash_profile`` file. `Read this for more information about the difference between login and non login shells <http://dghubble.com/blog/posts/.bashprofile-.profile-and-.bashrc-conventions/>`_. 
  
   See :ref:`configuring` if you need more information on how to set an environment variable. 

.. admonition:: Windows
 
      .. image:: icon_windows2.png

   To configure the pipeline, run the gpi-setup-windows.bat script. While this install script was written for the non-compiled version of the pipeline, it should also work for the compiled version. Ignore the warning that IDL is not in the ``PATH`` and you will end up setting a few environment variables you will not use.

Starting the DRP with the IDL Runtime
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The zip file contains, among other things, a directory called ``executables`` which contains .sav files needed by the Virtual Machine to run the pipeline:

 * ``gpi_launch_pipeline.sav`` starts the main data reduction session and status console 
 * ``gpi_launch_guis.sav`` starts the GUI session, including a launcher window that will allow the user to start the various GUIs.
 * ``gpitv.sav`` starts GPItv alone.

How to start the compiled code varies by operating system.

.. admonition:: Mac OS X, Linux

      .. image:: icon_mac2.png
      .. image:: icon_linux2.png

   On Unix-like operating systems, you can start the compiled code
   from the command line. The following commands assume that the environment variables ``$IDL_DIR`` and ``$GPI_DRP_DIR`` have been set, either by the ``gpi-setup-nix`` script or :ref:`manually <configuring>`::
      
        unix% $IDL_DIR/bin/idl -rt=$GPI_DRP_DIR/executables/gpi_launch_pipeline.sav
        unix% $IDL_DIR/bin/idl -rt=$GPI_DRP_DIR/executables/gpi_launch_guis.sav

   To conveniently start both required IDL sessions at once, there is a shell script ``scripts/gpi-pipeline`` which 
   launches two xterms and starts the pipeline and GUIs sessions in them. If you encounter problems when using this, 
   just manually start both the pipeline and GUI sessions as shown above. 



.. admonition:: Windows

    .. image:: icon_windows2.png

   On Windows, the ``executables`` directory contains three .exe files corresponding to the above named .sav files. 
   Double click any of these to start that component of the pipeline.

   You must manually start both the pipeline and GUIs sessions to use the pipeline interactively.



For any of the above OSes, you may also manually start the IDL Virtual Machine by itself, and it will present you with a file dialog for browsing to and selecting a .sav file to run.
See the `Exelis documentation on starting a runtime application <http://www.exelisvis.com/docs/StartingRuntimeApplication.html>`_ for more information.

Contents of the Distribution ZIP files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In addition to the ``executables`` directory already discussed, the code distribution ZIP file contains also the following directories:
 *  ``config``: this directory contains various pipeline configuration files, filter transmission FITS files, and other required ancillary data.
 *  ``recipe_templates``: this directory contains the template DRF that will be used by the parser to define which recipes should be used for a specific dataset.
 *  ``scripts``: this directory contains convenience scripts for starting the pipeline
 *  ``queue``: this empty directory will be automatically scanned by the controller for new recipes to be executed,
 *  ``log``: this empty directory serves to place the DRP log file of every reduction processed.
 *  ``executables/IDLxx``: (where ``xx`` is some version number) contains the IDL Virtual Machine itself and its assocated files 
 *  ``html``: A local copy of this HTML documentation for possible offline access.


If you have followed these steps successfully, you have installed the pipeline code. 
Proceed now to :ref:`configuring`.


.. _priorversions:


Download Links for Prior Versions
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

**Version 1.2.0** (2014 Nov 3): 
 * `gpi_pipeline_1.2.0_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.0_compiled.zip>`_ -  GPI pipeline compiled code only
 * `gpi_pipeline_1.2.0_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.0_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
 * `gpi_pipeline_1.2.0_runtime_linux.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.0_runtime_linux.zip>`_ - GPI pipeline compiled code plus IDL runtime for Linux
 * `gpi_pipeline_1.2.0_runtime_windows.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.0_runtime_windows.zip>`_ - GPI pipeline compiled code plus IDL runtime for Windows
 * `gpi_pipeline_1.2.0_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.2.0_source.zip>`_ -  GPI pipeline source code (available for reference)



**Version 1.1** (2014 May 1): 
 * `gpi_pipeline_1.1_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.1_compiled.zip>`_ -  GPI pipeline compiled code only
 * `gpi_pipeline_1.1_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.1_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
 * `gpi_pipeline_1.1_runtime_linux.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.1_runtime_linux.zip>`_ - GPI pipeline compiled code plus IDL runtime for Linux
 * `gpi_pipeline_1.1_runtime_windows.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.1_runtime_windows.zip>`_ - GPI pipeline compiled code plus IDL runtime for Windows
 * `gpi_pipeline_1.1_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.1_source.zip>`_ -  GPI pipeline source code (available for reference)



**Version 1.0.0** (2014 Feb 14): 
 * `gpi_pipeline_1.0_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.0_compiled.zip>`_ -  GPI pipeline compiled code only
 * `gpi_pipeline_1.0_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.0_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
 * `gpi_pipeline_1.0_runtime_linux.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.0_runtime_linux.zip>`_ - GPI pipeline compiled code plus IDL runtime for Linux
 * `gpi_pipeline_1.0_runtime_windows.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.0_runtime_windows.zip>`_ - GPI pipeline compiled code plus IDL runtime for Windows
 * `gpi_pipeline_1.0_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_1.0_source.zip>`_ -  GPI pipeline source code (available for reference)


**Version 0.9.4** (2014 Jan 7):
 * `gpi_pipeline_0.9.4_r2360_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.4_r2360_compiled.zip>`_ -  GPI pipeline compiled code only
 * `gpi_pipeline_0.9.4_r2360_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.4_r2360_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
 * `gpi_pipeline_0.9.4_r2360_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.4_r2360_source.zip>`_ -  GPI pipeline source code (available for reference)

.. comment 
    **Version 0.9.2** (2013 Sept 5):
     * `gpi_pipeline_0.9.2_r1926_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.2_r1926_compiled.zip>`_ -  GPI pipeline compiled code only
     * `gpi_pipeline_0.9.2_r1926_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.2_r1926_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
     * `gpi_pipeline_0.9.2_r1926_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.2_r1926_source.zip>`_ -  GPI pipeline source code (available for reference)
    **Version 0.9.1** (2013 July 18):
     * `gpi_pipeline_0.9.1_compiled.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.1_compiled.zip>`_ -  GPI pipeline compiled code only
     * `gpi_pipeline_0.9.1_runtime_macosx.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.1_runtime_macosx.zip>`_ - GPI pipeline compiled code plus IDL runtime for Mac OS X
     * `gpi_pipeline_0.9.1_source.zip <http://www.stsci.edu/~mperrin/gpi/downloads/gpi_pipeline_0.9.1_source.zip>`_ -  GPI pipeline source code (available for reference)

.. comment 
   **Temporary pre-release copies of the code hosted as follows**
   * Updated version as of April 29, 2013 (untested): http://www.stsci.edu/~mperrin/software/gpidata/downloads/
     (Not a zip file, just wget or rsync to get the entire directory or retrieve individual files at your choice)
   * Updated version as of June 7, 2012 (untested): http://di.utoronto.ca/~maire/pipeline.zip



