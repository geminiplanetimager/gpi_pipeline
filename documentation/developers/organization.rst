Pipeline Code Internal Organization
########################################


Major software components and object classes
================================================

The GPI data pipeline is implemented in object-oriented fashion using IDL classes. Some classes provide GUI windows, other provide
internal components that don't directly draw to the screen. 

This page briefly summarizes the different components. For detailed documentation
on the functions and variables internal to the following, please see the
comments in the source code directly. 




Internals: (mostly in pipeline/backbone directory)
--------------------------------------------------

The following are all object classes, so see e.g. ``launcher__define.pro`` for the source code for the "launcher" object.

gpipipelinebackbone
	The main object class of the pipeline! Loops forever waiting for 
        recipe files and processes them one at a time when they arrive. 

drf
	High level wrapper class for recipe files (aka DRFs). 
        The actual work of parsing the XML is done in the gpidrfparser class, but 
        the interface of that one is not so user friendly due to how IDL's XML parsing system (ffXMLParser class) works. 

gpidrfparser
	Lower-level class for parsing an XML recipe file. Avoid using this 
        directly if you can - the drf class is generally more convenient.

gpidrsconfigparser
	Lower level class for parsing an XML primitives config 
        file (that is, the list of all available primitives). 

gpicaldatabase
	:ref:`calibdb` class. Maintains an index of available 
        calibration files and has tools for looking up the best one for a given task. 

launcher 
        This class provides the bidirectional communication flow between the two IDL sessions.
        *This class can be both an internal and a GUI, depending on how it's invoked.*
        In one IDL session, it is started directly to create and run the Launcher window that provides buttons to 
        start the other programs. Another copy of it gets loaded inside 
        gpipipelinebackbone, where it provides the inter-process communication pipeline that 
        lets the backbone talk to the Launcher window running in the other IDL session. 


GUIs:
----------

launcher
	See description above.

gpistatusconsole
	:ref:`status_console` window object definition.  This is the one GUI that runs
        in the same IDL session with the backbone itself, allowing direct control of it. 

gpi_gui_base
        *Not used directly, just a base class from which the other windows are derived. Provides common infrastructure*

automaticreducer
	:ref:`autoreducer` window object definition

gpi_recipe_editor
	:ref:`recipe_editor` window object definition

parsergui
	:ref:`data_parser` window object definition

queueview
	:ref:`queue_viewer` window object definition




Function Call Hierarchy when Running Recipes
===============================================

The main loop of the pipeline occurs inside the ``gpipipelinebackbone::run_queue`` method.


The call hierarchy inside gpipipelinebackbone is something like the following. Each indentation indicates being one level deeper in the call stack or inside a loop Each of these methods is part of gpipipelinebackbone.

::

   gpipipelinebackbone::Run_queue		(loops forever checking the queue)
	gpipipelinebackbone::run_one_recipe	(called when a recipe is found)
		parses recipe
		gpipipelinebackbone::Reduce
		    loops over input files in that recipe
			loops over modules in that recipe
				gpipipelinebackbone::RunModule
					invokes actual primitive code here...
				update log and status window for each primitive
		     update log and status window for each file
		update status console, clean up recipe file
	Check for user input from status console buttons
        Check for any new recipe files to process
        loop to continue running queue

		
 


Common Blocks
===================

The pipeline uses some IDL common blocks to pass global variables between different routines. 

.. note::
  **TODO**

  Document here the common block variables in the code, in both the APP_CONSTANTS and PIP common blocks. 
  TBD if it is possible to merge both? There is some low level stuff here that is probably obsolete and
  could be cleaned up.


