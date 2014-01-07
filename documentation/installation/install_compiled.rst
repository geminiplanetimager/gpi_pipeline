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


.. comment 
    ## DO NOT EDIT THIS LINE ## Marker for automated editing of this file by gpi_release.py
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



Obtain the desired zip file and uncompress it to a directory of your choosing. Remember this path for use when configuring DRP paths in the next section.


Starting the DRP with the IDL Runtime
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The zip file contains, among other things, a directory called ``executables`` which contains .sav files needed by the Virtual Machine to run the pipeline:

 * ``gpi_launch_pipeline.sav`` starts the main data reduction session and status console 
 * ``gpi_launch_guis.sav`` starts the GUI session, including a launcher window that will allow the user to start the various GUIs.
 * ``gpitv.sav`` starts GPItv alone.

How to start the compiled code varies by operating system.

.. admonition:: Mac OS X

      .. image:: icon_mac2.png

   On Mac OS X, the ``executables`` directory contains three Applescript files corresponding to the above named .sav files. 
   Double click any of these to start that component of the pipeline.  You can also start compiled code
   from the command line ::
      
        unix% idl -rt=/path/to/executables/gpi_launch_pipeline.sav

   To conveniently start both required IDL sessions at once, there is a shell script ``scripts/gpi-pipeline`` which 
   launches two xterms and starts the pipeline and GUIs sessions in them.

   You may need to set the environment variable IDL_DIR to the ``executables\idl##`` directory.


.. admonition:: Linux

      .. image:: icon_linux2.png

   You can start compiled code from the command line ::
      
        unix% idl -rt=/path/to/executables/gpi_launch_pipeline.sav

   To conveniently start both required IDL sessions at once, there is a shell script ``scripts/gpi-pipeline`` which 
   launches two xterms and starts the pipeline and GUIs sessions in them.

   You may need to set the environment variable IDL_DIR to the ``executables\idl##`` directory.


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




