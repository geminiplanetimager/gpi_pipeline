
Release Guide: Versions, Version Tracking, etc
================================================


.. warning:: 

        This page obviously not yet complete. Rough draft notes in progress, consult Subversion red book for details. 

        This page is not likely to be of much use to anyone other than members of the GPI team.



Creating a New Release Version
-------------------------------

.. warning::
  
   The following needs to be updated now that there's a "public" branch separate from the trunk.


The first step is to tag the released version in subversion. 
Then copy the relevant trunk directories into that release directory::

        setenv VER 0.x.y
        svn copy https://repos.seti.org/gpi/pipeline/branches/public https://repos.seti.org/gpi/pipeline/tags/${VER} -m "Release copy of pipeline version ${VER}"
        svn copy https://repos.seti.org/gpi/external/trunk https://repos.seti.org/gpi/external/tags/${VER} -m "Release copy of pipeline external dependencies version ${VER}"


This does the update on the *server* only. To update your local copy of the release directory, and make a release source code zip file::
        
        svn checkout https://repos.seti.org/gpi/pipeline/branches/public public_pipeline
        (Here you may make any desired changes to the public branch such as removing files which are still under development and not yet ready to release)
              

To create the compiled executables ('sav files' in IDL speak), run the ``gpi_compiler`` routine in IDL, and when prompted enter the desired output directory.
Before starting IDL, you may wish to make sure that your IDL ``$IDL_PATH`` is free of any of your personal routines or other IDL code, so you can be sure you're compiling 
the versions in the pipeline directory. You should also make sure that your ``$IDL_PATH`` is pointing toward the public directory::

        shell ~ > setenv IDL_PATH "+/home/username/public_pipeline:+/Applications/itt/idl/idl81/lib"
        IDL> gpi_compiler
        Enter name of the directory where to create executables:  ~/tmp/gpi
        [very long series of informative messages during compilation]
        % GPI_COMPILER: Compilation done.
        % GPI_COMPILER: The ZIP files ready for distribution are:
        % GPI_COMPILER:       ~/tmp//gpi_pipeline_0.9.3_r2345M_runtime_macosx.zip
        % GPI_COMPILER:       ~/tmp//gpi_pipeline_0.9.3_r2345M_compiled.zip
        % GPI_COMPILER:       ~/tmp//gpi_pipeline_0.9.3_r2345M_source.zip



If you are compiling on Mac or Linux, gpi_compiler will automatically zip up the output into three zip files:

 * a platform independent one containing just the save files
 * and an OS dependent one that contains also the IDL runtime virtual machine
 * and a matching source code ZIP file as well. 


.. note::
  It is normal to see a handful of compiler error messages when building the pipeline. Generally these are scripts or
  code blocks that get sourced into other routines, that are not intended to be compiled on their own. The gpi_compiler
  infrastructure ought to be updated to be smarter about ignoring these, but in the mean time these errors 
  can just be ignored.



Upload the resulting zip files to the desired download locations.
Update the documentation source and recompile it using Sphinx.

Switching to a given release on subversion
-----------------------------------------------

In your working copy of the 'pipeline' directory, for instance::

        svn switch https://repos.seti.org/gpi/Releases/0.9.0/pipeline

To check this has taken effect::

        svn info

and check the URL line in the output has the release tag in it. 
