.. _starting_pipeline:

Starting the GPI Data Pipeline 
##################################################

The pipeline software is designed to run in two different IDL sessions: 

* one for the data processing,

* and one for the graphical interfaces. 

Splitting these tasks between two processes enables the GUIs to remain responsive even while 
long computations are running.


Exactly how you start up those two IDL sessions varies with operating system, and with whether you have installed from source or compiled code.


Starting from source code (either from the repository or zip files)
==========================================================================


.. admonition:: Starting the pipeline manually

    .. image:: ../shared_images/icon_mac2.png
    .. image:: ../shared_images/icon_linux2.png
    .. image:: ../shared_images/icon_windows2.png
 
  On any OS you can simply start up the pipeline manually.

  Start an IDL session. Run 

     .. code-block:: idl

       IDL> gpi_launch_pipeline 
     
  Start a second IDL session. Run 

     .. code-block:: idl

       IDL> gpi_launch_guis

  If in the first IDL session you see a line reading "Now polling for
  data in such-and-such directory", and the Status Console and
  Launcher windows are displayed as :ref:`shown below <itsworking>`, then the pipeline has launched successfully.



.. admonition:: Mac OS and Linux startup script

    .. image:: ../shared_images/icon_mac2.png
    .. image:: ../shared_images/icon_linux2.png
 
  On Linux or Mac, a convenient shell script is provided in ``pipeline/scripts`` that starts 2 xterms, each with an IDL session, and runs the above two commands. This script is called ``gpi-pipeline``:

    ::

     shell> gpi-pipeline

  You should see two xterms appear, both launch IDL sessions, and various
  commands run and status messages display. 

  If in the second xterm you see a line reading "Now polling for
  data in such-and-such directory", and the Status Console and
  Launcher windows are displayed as :ref:`shown below <itsworking>`, then the pipeline has launched successfully.

.. warning::
   In order for the ``gpi-pipeline`` script to work, your system must be set up such that IDL can be launched from the command line by running ``idl``.  The script will not execute correctly if you use an alias to start IDL rather than having the IDL executable in your path. In this case you will probably get an error in the xterms along the lines lines of: 'xterm: Can't execvp idl: No such file or directory'. To check on how you start IDL, run: ::
   
        shell> which idl

   A blank output (or an output that says 'aliased') means that idl is not in your path.  To add it, either edit your ``$PATH`` variable, or go to a user-writeable directory in your path (you can check which directories are in your path by running ``echo $PATH``).  Then create a symbolic link in the directory by running::
        
        shell> ln -s /path/to/idl idl

   If you encounter problems with the startup script, just start the IDL sessions manually as described above. 



.. admonition:: Windows startup script

    .. image:: ../shared_images/icon_windows2.png
 
   On Windows, there is a batch script in the ``pipeline/scripts`` directory called ``gpi-pipeline-windows.bat``. Double click it to start the GPI pipeline. 

   If in the first IDL session you see a line reading "Now polling for
   data in such-and-such directory", and the Status Console and
   Launcher windows are displayed as :ref:`shown below <itsworking>`, then the pipeline has launched successfully.

   For convenience, you can create a shortcut of ``gpi-pipeline-windows.bat`` by right clicking on the file and selecting the option to create a shortcut. You can then place this on your desktop, start menu, or start screen to launch the pipeline from where it is convenient for you. 

   If you encounter problems with the startup script, just start the IDL sessions manually as described above. 


Starting compiled code with the IDL Virtual Machine
==========================================================================

The compiled binary versions of DRP applications that can be started with the
IDL Virtual Machine are:

*  ``gpi_launch_pipeline.sav`` starts the pipeline controller and the status console

*  ``gpi_launch_guis.sav`` starts the Launcher and other GUIs. 

These files are located in the ``executables`` subdirectory of the distributed zip files. 


How to run a .sav file in the IDL Virtual Machine depends on your operating system.  Please see `Exelis' page on Starting a Virtual Machine Application <http://www.exelisvis.com/docs/StartingVirtualMachineApplication.html>`_ for more details. 

.. admonition::  Mac OS and Linux manual startup of the Virtual Machine

    .. image:: ../shared_images/icon_mac2.png
    .. image:: ../shared_images/icon_linux2.png
    

  Mac and Linux users can launch the IDL virtual machine and then tell it to launch a particular .sav file. You'll need to repeat this for the two GPI pipeline IDL sessions. 
  The following commands assume that the environment variables ``$IDL_DIR`` and ``$GPI_DRP_DIR`` have been set, either by the ``gpi-setup-nix`` script or :ref:`manually <configuring>`:
      
  1. Enter the following at the command line to start an IDL session for the pipeline backbone::

        unix% $IDL_DIR/bin/idl -rt=$GPI_DRP_DIR/executables/gpi_launch_pipeline.sav

  2.  The IDL Virtual Machine logo window will be displayed with a "Click to continue" message.  Click anywhere in the IDL logo window to continue and run the .sav file.

  3. Repeat the above process to start a second IDL session for the pipeline GUIs::

        unix% $IDL_DIR/bin/idl -rt=$GPI_DRP_DIR/executables/gpi_launch_guis.sav



  You may also launch the IDL Virtual Machine and use its file selection menu to locate the .sav file to run. 
  
  1. Enter the following at the UNIX command line::

       >>>  $IDL_DIR/bin/idl -vm  
    
  2. The IDL Virtual Machine logo will be displayed. Click anywhere in the IDL Virtual Machine window to display a file selection dialog box.

  3. Locate and select the desired .sav file and click OK to open that file.

   If in the first IDL session you see a line reading "Now polling for
   data in such-and-such directory", and the Status Console and
   Launcher windows are displayed as :ref:`shown below <itsworking>`, then the pipeline has launched successfully.


.. admonition:: Mac OS and Linux startup script

    .. image:: ../shared_images/icon_mac2.png
    .. image:: ../shared_images/icon_linux2.png
 
   Just like for the source code install, a script is provided in ``pipeline/scripts`` that launches 2 IDL sessions, and starts the pipeline code. 
   While the under the hood implementation is slightly different, the script name and effective functionality are identical.  ::

      shell> gpi-pipeline

   If you encounter problems with the startup script, just start the IDL sessions manually as described above. 


  
.. warning:: 

      .. image:: ../shared_images/icon_mac2.png
 
    On Mac OS, in theory it ought to be possible to start the pipeline by double clicking the .sav files or .app bundles produced by the IDL compiler. However, if you start them from the Finder, then they will not have access to any environment variables that define paths, since those are set in your shell configuration files, which the Finder knows nothing about. 

    We recommend you start the IDL virtual machine settings from inside Terminal or an xterm, as described above. 

    If you really do want to start from double clicking in the Finder, you will need to define all the pipeline file paths using your ``.gpi_pipeline_settings`` file instead of via environment variables. See :ref:`configuring`.


.. admonition:: Windows manual startup of the Virtual Machine

    .. image:: ../shared_images/icon_windows2.png
 

  Most simply, if your installation of Windows has file extensions configured to associate .sav files with IDL, you can just double click.

  
  To open a .sav file from the IDL Virtual Machine icon: 
  
  1.  Launch the IDL Virtual Machine in the usual manner for Windows programs, either by
      selecting the IDL Virtual Machine from your Start Menu, or double clicking a desktop icon for
      the IDL Virtual Machine.
      
  2.  Click anywhere in the IDL Virtual Machine window to display the file
      selection menu.
  
  3.  Locate and select the .sav file, and double-click or click Open to run it.


 
  To run a .sav file from the command line prompt: 
  
  1. Open a command line prompt. Select Run from the Start menu, and enter cmd.
  
  2.  Change directory (cd) to the ``IDL_DIR\bin\bin.platform`` directory, where
      platform is the platform-specific bin directory.
  
  3.  Enter the following at the command line prompt::

        >>> idlrt -vm=<path><filename>  

      where ``<path>`` is the path to the .sav file, and ``<filename>`` is the name of the .sav file.

  
 
.. _itsworking:

Pipeline IDL Session
==========================================================================

The IDL session running the pipeline should immediately begin to look for new recipes in the queue directory. A status
window will be displayed on screen (see below). On startup, the pipeline will
display status text that looks like::
  
  % Compiled module: [Lots of startup messages]
  [...]
  01:26:22.484  Now polling and waiting for Recipe files in /Users/mperrin/data/GPI/queue/

     *****************************************************
     *                                                   *
     *          GPI DATA REDUCTION PIPELINE              *
     *                                                   *
     *             VERSION 1.0                           *
     *                                                   *
     *         By the GPI Data Analysis Team             *
     *                                                   *
     *   Perrin, Maire, Ingraham, Savransky, Doyon,      *
     *   Marois, Chilcote, Draper, Fitzgerald, Greenbaum *
     *   Konopacky, Marchis, Millar-Blanchaer, Pueyo,    *
     *   Ruffio, Sadakuni, Wang, Wolff, & Wiktorowicz    *
     *                                                   *
     *      For documentation & full credits, see        *
     *      http://docs.planetimager.org/pipeline/       *
     *                                                   *
     *****************************************************


   Now polling for Recipe files in /Users/mperrin/data/GPI/queue/ at 1 Hz

  
If you see the "Now polling" line at the bottom, then the pipeline has launched
successfully.

The pipeline will create a status display console window (see screen shot
below). This window provides the user with progress bar indicators for ongoing
actions, a summary of the most recently completed recipes, and
a view of log messages. It also has a button for exiting the DRP (though you
can always just control-C or quit the IDL window too).  This is currently the
only one of the graphical tools that runs in the same IDL session as the main
reduction process. 


.. image:: ../shared_images/GPI-DRP-Status-Console.png
        :scale: 75%
        :align: center


Above: Snapshot of the administration console.

GUI IDL Session
==========================================================================

Several GUIs are available to select your data to be processed and to decide
which processes and primitives will be applied to the data.

The ``gpi_launch_guis`` commands starts the GUI Launcher window:

.. image:: ../shared_images/GPI-launcher.png
        :scale: 50%
        :align: center
 
These are described in detail in the :ref:`user-intro`.


