Release Guide: Versions, Version Tracking, etc
================================================


.. warning:: 

        This page contains working notes for making new release copies of the pipeline. 

        This page is not likely to be of much use to anyone other than members of the GPI team.

Branches
-----------

Most pipeline development happens in the ``trunk`` directory. Right now we have one branch directory, called ``public``. This allows the 
GPI team to have internal development routines that aren't included in the release zip files. (Note: the intent here is *not* to keep secrets 
from anybody, it's to avoid shipping incomplete/experimental/known-broken code in the public releases. These new functions will generally 
make their way into ``public`` once they're working properly.)


Creating a New Release Version
-------------------------------

This is a methodical process with lots of steps - eventually there may be a script to automate this better.  Once your pipeline codebase is ready to release: 


Creating a public branch and release tag in subversion
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

The first step in making a new release version is to increment the version number. This needs to be changed in two places. ::

        shell>  vi backbone/gpi_pipeline_version.pro
        shell>  vi documentation/conf.py
        shell>  svn commit backbone/gpi_pipeline_version.pro documentation/conf.py -m "increased version number to XX.YY"

Even though zip files do not yet exist at this point, you may wish to add placeholder links to the downloads pages. ::

        shell>  emacs documentation/installation/install_from_zips.rst
        shell>  emacs documentation/installation/install_from_repos.rst
        shell>  svn commit documentation -m "add download links for version XX.YY"

If you haven't already, check out the public branch to your computer, and copy the external directory into the same place so that you can
easily package it::

        shell>svn checkout https://repos.seti.org/gpi/pipeline/branches/public public/pipeline
	shell>svn checkout https://repos.seti.org/gpi/external/trunk public/external

Then, update the public release to the current version::	

        shell>cd public/pipeline
	shell>svn merge https://repos.seti.org/gpi/pipeline/trunk

You may possibly have to deal with and resolve conflicts if there are any at this point. Any file that has been updated since the last
release AND is not included in the public directory will probably appear as a conflict. You will have to resolve these before
proceeding. Check the conflicts against the list of files in exclude_from_releases.txt. If the file is on the exclude
list and is appearing as a conflict try::

       shell>svn resolve --accept working filename

where filename is the file in conflict. This will accept the (nonexistant) file in your local public directory.

After resolving conflicts, you should double check that none of the files in the exclude list remain in the public directory. It's painstaking, but necessary as sometimes one or two slip through. Then commit the public branch::

        shell> svn commit -m "Merged changes from trunk to public branch for version XX.YY"
 
The next step is to tag the released version in subversion. 
This is done by svn copying the relevant trunk directories into appropriate tags  directories, under both ``pipeline`` and ``external``::

        setenv VER 0.x.y
        svn copy https://repos.seti.org/gpi/pipeline/branches/public https://repos.seti.org/gpi/pipeline/tags/${VER} -m "Release copy of pipeline version ${VER}"
        svn copy https://repos.seti.org/gpi/external/trunk https://repos.seti.org/gpi/external/tags/${VER} -m "Release copy of pipeline external dependencies version ${VER}"

This does the update on the *server* only. To update your local copy of the release directory, you can do an ``svn update`` in your tags directory. 

.. warning::
   If you need to do this again after making some more changes, *don't* just repeat the above command, since that won't overwrite the first copy, it will make a second copy as a subdirectory of the first, which is almost certainly NOT what you want. 
   See also this article on `"Why caution is advised when svn copying directories" <http://kera.name/articles/2012/08/why-caution-is-advised-when-svn-copying-directories/>`_

        
Now to make the distribution zip files
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Before starting IDL, you should adjust your IDL ``$IDL_PATH`` so that it points at the ``public`` directory, and is free of any of 
your personal routines or other IDL code. This will ensure that you're compiling 
the versions in the pipeline directory.  For the ``external`` directory, either (1) update your existing copy to the latest trunk, or (2) check out a copy of the tagged version to make sure you have the latest.::
    
        shell> cd external
        shell> svn update
        % OR
        shell> svn checkout https://repos.seti.org/gpi/external/tags/${VER}


To create the compiled executables ('sav files' in IDL speak), run the ``gpi_compiler`` routine in IDL, and when prompted enter the desired output directory.
Thus in the end, after appropriately adjusting your ``$IDL_PATH``, you're ready to run ``gpi_compiler``::

        shell ~ > setenv IDL_PATH "+/home/username/public_pipeline:+/home/username/external:+/Applications/itt/idl/idl81/lib"
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
Update the documentation source to have the proper ZIP file locations, if needed, and recompile using Sphinx.
Email Franck to update the official documentation on http://docs.planetimager.org/pipeline/


If you find (as is often the case) that you need to make some last minute fixes after testing the release, you should: 

 * Make the fixes in `trunk`
 * Re-merge from `trunk` to `public` (hopefully fast and easy)
 * It may be easiest to just `delete the tag for that release <http://www.coderelic.com/2011/12/how-to-delete-a-tag-or-branch-in-subversion/>`_ and re-do the `svn copy` the public branch to that tag again. (You can also merge from the public branch into the tag.)


Switching to a given release on subversion
-----------------------------------------------

In your working copy of the '``pipeline``' directory, for instance::

        svn switch https://repos.seti.org/gpi/pipeline/tags/0.9.2/

To check this has taken effect::

        svn info

and check the URL line in the output has the release tag in it.
