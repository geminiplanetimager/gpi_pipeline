.. _launcher::

The Launcher
===================

The launcher is a fairly simple window that can be used to launch other GUIs.
It is the main process for the IDL session that runs the GUIs, and closing it will cause that half of the GPI pipeline
to exit, closing all other windows.


.. image:: GPI-launcher.png
        :scale: 50%
        :align: center
 
The main usage of this window is pretty self-explanatory: press one of the buttons to 
open the Data Parser, Recipe Editor, and so on. 

The 'Setup' menu contains a few commands which are mostly useful for pipeline debugging and
error recovery, and you can probably ignore:
 *  You can view the values of all directory paths used for the 
    data pipeline, and see whether each is set from an environment variable or the default value is used. 
 *  There are several commands for clearing and resetting the message queue and shared memory used to
    communicate between the two IDL sessions. These are mostly left over from development and debugging in earlier
    versions of the pipeline, and essentially no one should need to worry about these any more.


The Help menu lets you bring up this HTML documentation, or get information about the version of the
GPI data pipeline that you have installed. Similar menu items are present in most GPI GUI windows. 

