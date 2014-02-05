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

.. admonition:: Mac OS and Linux

    .. image:: ../shared_images/icon_mac2.png
    .. image:: ../shared_images/icon_linux2.png
 
  On Linux or Mac, a script is provided in pipeline/scripts that starts 2 xterms, each with an IDL session, and runs the two appropriate commands:

    ::

     shell> gpi-pipeline

  You should see two xterms appear, both launch IDL sessions, and various
  commands run. If in the second xterm you see a line reading "Now polling for
  data in such-and-such directory" at the bottom, and the GPI Status Console and
  Launcher windows are displayed, then the pipeline has launched successfully.

.. warning::
   In order for the ``gpi-pipeline`` script to work, your system must be set up such that IDL can be launched from the command line by running ``idl``.  The script will not execute correctly if you use an alias to start IDL rather than having the IDL executable in your path. In this case you will probably get an error in the xterms along the lines lines of: 'xterm: Can't execvp idl: No such file or directory'. To check on how you start IDL, run: ::
   
        shell> which idl

   A blank output (or an output that says 'aliased') means that idl is not in your path.  To add it, go to a user-writeable directory in your path (you can check which directories are in your path by running ``echo $PATH``).  Then create a symbolic link in the directory by running: ::
        
        shell> ln -s /path/to/idl idl

   Note that you can always start the pipeline using two separate IDL sessions as in the Windows instructions, below.  You can also edit the ``gpi-pipeline`` script with the full path of your IDL binary.

.. admonition:: Windows

    .. image:: ../shared_images/icon_windows2.png
 
 On Windows, there is a batch script in the ``pipeline/scripts`` directory called ``gpi-pipeline-windows.bat``. Double click it to start the GPI pipeline. 

 For convenience, you can create a shortcut of ``gpi-pipeline-windows.bat`` by right clicking on the file and selecting the option to create a shortcut. You can then place this on your desktop, start menu, or start screen to launch the pipeline from where it is convenient for you. 

.. note::
  Alternatively, on any OS you can use the following to start up the pipeline manually:

  Start an IDL session. Run 

     ::

       IDL> gpi_launch_pipeline 
     
  Start a second IDL session. Run 

     ::

       IDL> gpi_launch_guis



Starting compiled code with the IDL Virtual Machine
==========================================================================

The compiled binary versions of DRP applications that can be started with the
IDL Virtual Machine are:

*  gpi_launch_pipeline.sav starts the pipeline controller, the administration console

*  gpitv.sav starts GPItv

*  gpi_launch_guis.sav starts an application that will allow the user to start the DRF-GUI, the Parser, GPItv, in addition to some other applications (DRF queue viewer, DST).

How to run a .sav file in the IDL Virtual Machine depends on your operating system. 

.. admonition:: Mac OS and Linux

    .. image:: ../shared_images/icon_mac2.png
    .. image:: ../shared_images/icon_linux2.png
 
  Just like for the source code install, a script is provided in pipeline/scripts that launches 2 IDL sessions, and starts the pipeline code. 
  While the under the hood implementation is slightly different, the script name and effective functionality are identical::

     shell> gpi-pipeline

  You should see two xterms appear, both launch IDL sessions, and various
  commands run. If in the second xterm you see a line reading "Now polling for
  data in such-and-such directory" at the bottom, and the GPI Status Console and
  Launcher windows are displayed, then the pipeline has launched successfully.


  **Alternatives**

  You may also choose to start the IDL runtime sessions manually, as follows. 
  The first step is to launch the IDL Virtual Machine from the command line. To run a .sav file in the IDL Virtual Machine: 
  
  1. Enter the following at the UNIX command line::

       >>>idl -vm=<path><filename>  

     where <path> is the complete path to the .sav file and <filename> is the name of the .sav file. The IDL Virtual Machine window is displayed.
  
  2.  Click anywhere in the IDL Virtual Machine window to close the window and run the .sav file.
  
  You may also launch the IDL Virtual Machine and use the file selection menu to locate the .sav file to run: 
  
  1. Enter the following at the UNIX command line::

       >>>idl -vm  
     
     The IDL Virtual Machine window is displayed.
  
  2. Click anywhere in the IDL Virtual Machine window to display the file selection menu.

  3.  Locate and select the .sav file and click OK.

.. admonition:: Windows

    .. image:: ../shared_images/icon_windows2.png
 
  Windows users can drag and drop the .sav file onto the IDL Virtual Machine
  desktop icon, launch the IDL Virtual Machine and open the .sav file, or launch
  the.sav file in the IDL Virtual Machine from the command line. 
  
  To use drag and drop: 
  
  1.  Locate and select the .sav file in Windows Explorer.
  
  2.  Drag the file icon from the Windows Explorer list and drop it onto the IDL
      Virtual Machine 8.0 icon that has been created for you on the desktop. The
      IVM window is displayed.
  
  3.  Click anywhere in the IDL Virtual Machine window to close the window and
      run the .sav file.
  
  To open a .sav file from the IDL Virtual Machine icon: 
  
  1.  Launch the IDL Virtual Machine in the usual manner for Windows programs, either by
      selecting the IDL Virtual Machine from your Start Menu, or double clicking a desktop icon for
      the IDL Virtual Machine.
      
  2.  Click anywhere in the IDL Virtual Machine window to display the file
      selection menu.
  
  3.  Locate and select the .sav file, and double-click or click Open to run it.
  
  To run a .sav file from the command line
  prompt: 
  
  1. Open a command line prompt. Select Run from the Start menu, and enter cmd.
  
  2.  Change directory (cd) to the ``IDL_DIR\bin\bin.platform`` directory where
      platform is the platform-specific bin directory.
  
  3.  Enter the following at the command line prompt::

        >>> idlrt -vm=<path><filename>  

      where ``<path>`` is the path to the .sav file, and ``<filename>`` is the name of the .sav file.


  
.. admonition:: Mac OS 

    .. image:: ../shared_images/icon_mac2.png
 
  Macintosh users can also drag and drop the .sav file onto the IDL Virtual Machine desktop icon, launch the IDL Virtual Machine and open the .sav file, or launch the.sav file in the IDL Virtual Machine from the command line. 
  
  To use drag and drop: 
  
  1. Locate and select the .sav file in the Finder.
  
  2. Drag the file icon from the Finder and drop it onto the IDL 8.0 Virtual
     Machine icon that has been created for you on the desktop. The IDL Virtual
     Machine window is displayed.
  
  3. Click anywhere in the IDL Virtual Machine window to close the window and run
     the .sav file.
  
  To open a .sav file from the IDL Virtual Machine icon: 
  
  1.  Double-click the IDL 6.4 Virtual Machine icon to display the IDL Virtual
      Machine window:
  
  2.  Click anywhere in the IDL Virtual Machine window to close the window and
      display the file selection menu.
  
  3. Locate and select the .sav file and click OK.
  
 

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


