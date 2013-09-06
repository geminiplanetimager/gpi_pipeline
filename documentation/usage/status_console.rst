.. _status_console:

Status Console
===================


The Status Console window lets you monitor and control the ongoing execution of pipeline tasks.
You can view current operating tasks, review log messages, refresh the configuration, and/or shut down the pipeline.

.. image:: GPI-DRP-Status-Console.png
        :scale: 75%
        :align: center


When a recipe begins to be processed, the Status Console window will
immediately begin displaying the progress of the recipe. Two progress bars
display the fractional completion of the overall recipe and the current FITS file being processed as part of that recipe. 
A scrollable Pipeline
Log Messages box provides a user accessible description of the
progress (these log messages also appear in the IDL session window itself). The status window also displays the
filename for the latest recipe and input and output FITS files, along with listing the current
action (during execution) and various configuration paths.


.. **Description of the window and its elements to go here**


The status console window also allows some control over the pipeline via buttons along the bottom of the window.  

 * The **Rescan Calib. BD** button will rescan the calibration database
   directory to re-create the index. This is useful if you've manually added or
   removed files.
 * The **Rescan DRP Config** button will rescan the data reduction pipeline
   :ref:`configuration files <configuring>`. Use this if you wish to change some
   setting while the pipeline is active. For users running the pipeline from IDL
   source code, this button will also reindex the available primitives and
   recompile them, which is very helpful when editing code.
 * The recipe queue can be flushed (**Clear Recipe Queue button**), which
   deletes any pending recipes without execution (but asks the user for
   confirmation before doing so, fear not!)
 * and the current recipe file can be aborted (**Abort Current Recipe**). 
 * At any point, the user may quit the pipeline by pressing **Quit GPI DRP**, or
   simply by closing the the IDL session (e.g. by closing the window, or
   pressing Ctrl-C). 


