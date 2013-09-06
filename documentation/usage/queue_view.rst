.. _queue_viewer:

The Queue Viewer
===================

The Queue Viewer may be accessed from the GPI Launcher GUI window that is accessed by opening an IDL session in the GPI data directory and typing 'gpi_launch_guis'. The Queue Viewer is a rarely used tool for displaying the recipe files located in the GPI Queue directory. The window provides a table listing the directory and filename for each recipe along with the recipe type, and the number of FITS files used in each recipe. A history dialogue box near the bottom of the window gives updates when new recipes are added to the queue. 

Recipes are color coded for progress: green for completed recipes with a filename ending in '.done.xml', blue for recipes in progress with a filename ending in '.working.xml', and red for recipes that have failed with filenames ending in '.failed.xml'. If a recipe is created using the Recipe Editor and not by the user alone, the filenames provide the date and time the recipe was written. For example, a file created on August 24th, 2012 at 5:13:50 pm will be given the filename '20120824_171350_drf.waiting.xml'. 

From the Queue Viewer, the user has some control over the recipes via a row of buttons along the bottom of the window. The user may 'Rescan' the queue directory, clear all recipes with file names ending in '.done.xml' (Clear Completed button), Re-queue a selected recipe, View/Edit a recipe in the Data Parser gui (View EDIT in DRFGUI button), Delete a selected recipe, delete all recipes, and, of course, close the gueue viewer.  


.. **document this**
