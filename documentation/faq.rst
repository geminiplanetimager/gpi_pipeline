.. _frequently-asked-questions:


Frequently Asked Questions
=============================

Installation
^^^^^^^^^^^^^^^^^^^^^^^^^

When trying to start the pipeline, I get the error "xterm: Can't execvp idl: No such file or directory"
----------------------------------------------------------------------------------------------------------
This cryptic message means that you are trying to start the gpi-pipeline script without having the idl executable
in your path. Perhaps you have it aliased instead, but that's not detected by the gpi-pipeline starter script. 
You can either (1) change your $PATH to include the directory with idl, (2) put a symlink pointing to idl in some
directory already in your path, or (3) edit your local copy of the gpi-pipeline script to explicitly set the full
path to the idl executable.

Why did the pipeline stop and return to a prompt in the middle of my reduction?
----------------------------------------------------------------------------------
This is most likely an IDL_PATH issue. See 'How do I diagnose an IDL_PATH error?'
 
How do I diagnose an IDL_PATH error?
----------------------------------------------------------
The user should check to make sure that the proper dependency is being called. For example, if the pipeline crashes in a function called APER (which is part of the IDL astrolib library). The user should issue the command:

.. code-block:: idl 

    IDL> which, aper

Doing this will show each aper.pro file that is in the ``$IDL_PATH``, the one that is in the pipeline directory should be the first on the list. If it is not, then the pipeline directory does not have the priority when calling this function. To correct this, ensure that the pipeline directory comes before the other directories in your IDL path by setting the ``$IDL_PATH`` in your setup script (or wherever you set the ``$IDL_PATH variable``) as follows:

For sh/csh/tcsh shells - ``setenv IDL_PATH "+/home/labuser1/GPI/pipeline:${IDL_PATH}"``

For bash shells - ``export IDL_PATH="+/home/labuser1/GPI/pipeline/${IDL_PATH}"``


