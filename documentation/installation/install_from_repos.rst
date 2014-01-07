
.. _installing-from-repos:

Installing from the Source Code Repository
=============================================


This section describes how to install the pipeline in development mode, for
members of the GPI team and Gemini staff. 

.. note::
    This method requires you have an IDL license. If you do not have an IDL
    license, please refer to  :ref:`this page <installing-from-compiled>` for 
    installing compiled executables instead.


The GPI Pipeline souce code is developed using a Subversion version control
repository hosted at the SETI Institute.  GPI team members should see the `GPI
Computer Account Setup document <https://docs.google.com/document/d/1-d6bnsL7Ax7JD6dwoyJijBBRO0rQIei16HgHff2J9Zc/>`_ for instructions to obtain an account on this
repository.

.. note::
    If you are not familiar with version control, you may wish to see `this intro to version control <http://betterexplained.com/articles/a-visual-guide-to-version-control/>`_.

Once you have that account, in a directory of your choosing (preferably
somewhere inside your ``$IDL_PATH``) execute the commands:

  >>> svn checkout https://repos.seti.org/gpi/pipeline/trunk pipeline --username <yourusername>
  >>> svn checkout https://repos.seti.org/gpi/external/trunk external --username <yourusername>


The above commands will download the GPI data pipeline and associated tools, plus a
directory containing external dependencies of the code, for instance the
Goddard IDL library, the Coyote library, etc. You may already have copies of
many of these external routines in your own IDL library, in which case you can
delete the excess copies from this directory if you so desire. Two folders (pipeline and external) will be created in the directory from which you performed the command. 

.. warning::
    All code has been tested using the versions of external program in the repository.  Error-free operation is not guaranteed for other versions of these libraries. The usual caveats about name collisions between different versions of IDL routines apply.   If you have old versions of e.g. the Goddard IDL library functions in your ``$IDL_PATH``, you may encounter difficulties. We suggest placing the data pipeline code first in your ``$IDL_PATH``.


.. admonition:: Mac OS and Linux

    .. image:: icon_mac2.png

    .. image:: icon_linux2.png
  
  On Mac OS and Linux, you will likely want to add the ``pipeline/scripts`` subdirectory
  to your shell's ``$PATH``. 
  
For users having IDL 8.2+, the str_sep.pro program is now an obsolete command. Although no pipeline source code calls this function, it is still used in other external dependencies. For the time being, users should add the ``idl/lib/obsolete folder to their`` ``$IDL_PATH`` to remedy this issue.


Proceed now to :ref:`configuring`.


