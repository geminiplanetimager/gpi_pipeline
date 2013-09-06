
Appendix: Rarely-Used and/or Nonsupported Advanced Features
#############################################################


Command line invocation of a single recipe
-------------------------------------------

For testing purposes, it is possible to invoke the pipeline in a mode
where it will process one single recipe and then exit. This can be useful if
you want to test some particular piece of functionality, script batch execution of several recipes in
some linked order, etc. ::

   IDL> gpi_launch_pipeline, single='my_recipe.xml',/noexit
   [IDL processes that recipe file and then returns to the IDL command line]


Running without graphics
---------------------------

Sometimes it is useful to run the pipeline in a mode completely without any graphics
(most often, this is if you have sshed to some remote machine and want to test something
quickly, without the overhead of a forwarded X11 connection). This can be done by starting
the pipeline with the ``nogui`` switch::

        IDL> gpi_launch_pipeline,/nogui

The pipeline status console window will not launch. If you do not run the gpi_launch_guis command,
none of the other GUIs will run either. Any pipeline attempts to invoke gpitv with the outputs
from data processing will silently be ignored. 


Interfacing with Python
------------------------

There exist various tools for interacting with the GPI pipeline from Python, including
editing and manipulating recipe files, creating new recipes, checking
pipeline configuration settings, and working with GPI data.  All of this code is
officially unsupported but can be made available to interested parties on a
collaborative, shared risk basis. Please contact Marshall Perrin if interested. 


Calibration Database Viewer
-----------------------------

There is a graphical interface for viewing the contents of the Calibration Database. 
This allows quick and easy browsing, sorting, and selecting of the files there, including
filtering by instrument configuration and date. 

.. image:: fig_caldb_viewer.png
        :scale: 50%
        :align: center

This tool is written in Python and requires the wxpython widgets toolkit. It is distributed
separately from the main IDL data pipeline packages. Please contact Marshall Perrin if interested.

Simple Recipe Creator
-----------------------------

There is a simple recipe creation tool, which allows the user to choose one or more FITS files and then apply
one of the predefined recipe templates to those files. The steps in the recipe cannot be edited with this tool; 
it's just for applying templates to selected files.

.. image:: fig_simple_rec_ed.png
        :scale: 50%
        :align: center

This tool is written in Python and requires the wxpython widgets toolkit. It is distributed
separately from the main IDL data pipeline packages. Please contact Marshall Perrin if interested.
