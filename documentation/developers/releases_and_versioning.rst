
Release Guide: Versions, Version Tracking, etc
================================================


.. warning:: 

        This page obviously not yet complete. Rough draft notes in progress, consult Subversion red book for details. 

        This page is not likely to be of much use to anyone other than members of the GPI team.


Repository organization
----------------------------

is a bit nonstandard. We've got a bunch of related trunk directories, for historical reasons, and one release directory for release tags.
We're trying to keep things pretty simple and not branch the code significantly, for the most part... 



Creating a New Release Version
-------------------------------

The first step is to tag the released version in subversion. 

In the Release directory in your local copy::

        svn mkdir 0.x.y
        svn commit -m "Creating directory for release version 0.x.y"

Then copy the relevant trunk directories into that release directory::

        setenv VER 0.x.y
        svn copy https://repos.seti.org/gpi/pipeline https://repos.seti.org/gpi/Releases/${VER}/pipeline -m "Release copy of pipeline version ${VER}"
        svn copy https://repos.seti.org/gpi/gpitv https://repos.seti.org/gpi/Releases/${VER}/gpitv -m "Release copy of pipeline/gpitv version ${VER}"
        svn copy https://repos.seti.org/gpi/external https://repos.seti.org/gpi/Releases/${VER}/external -m "Release copy of pipeline/external version ${VER}"
        svn copy https://repos.seti.org/gpi/documentation https://repos.seti.org/gpi/Releases/${VER}/documentation -m "Release copy of pipeline documentation version ${VER}"


This does the update on the *server* only. To update your local copy of the release directory, and make a release source code zip file::
        
        cd 0.x.y
        svn update
        cd ..
        rsync -av 0.x.y/ gpi_pipeline_0.x.y     # note that the / at the end of 0.x.y is important here...
        zip -r gpi_pipeline_0.x.y_source.zip gpi_pipeline_0.x.y
        

To create the compiled executables ('sav files' in IDL speak), run the ``gpi_compiler`` routine in IDL, and when prompted enter the desired output directory.
Before starting IDL, you may wish to make sure that your IDL `$IDL_PATH` is free of any of your personal routines or other IDL code, so you can be sure you're compiling 
the versions in the pipeline directory::

        shell ~ > setenv IDL_PATH "+/home/username/gpi_software:+/Applications/itt/idl/idl81/lib"
        IDL> gpi_compiler
        Enter name of the directory where to create executables:  ~/tmp/gpi
        [very long series of informative messages during compilation]
        % GPI_COMPILER: Compilation done.
        % GPI_COMPILER:    Output is in ~/tmp/gpi/pipeline-0.9.0


If you are compiling on Mac or Linux, gpi_compiler will automatically zip up the output into two zip files:

 * a platform independent one containing just the save files
 * and an OS dependent one that contains also the IDL runtime virtual machine


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
