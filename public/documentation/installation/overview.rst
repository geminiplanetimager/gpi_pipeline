.. _installation_overview:

Installation Overview
========================

There are three different general methods by which the pipeline can be
installed. These are described on the next three pages of this manual.

1. :ref:`installing-from-zips` available from the GPI team web site, for users who have their own
   licensed copies of IDL.

2. :ref:`installing-from-repos` directly. This provides direct access to the latest development code from the team's Subversion version control
   repository, appropriate for GPI team members and Gemini staff who may be
   editing pipeline code. Users must also have a licensed copy of IDL.

3. :ref:`installing-from-compiled` virtual machine,
   for users who do not have their own copies of IDL. 

Once the pipeline is installed, one must :ref:`configure it 
<configuring>` by setting a few items such as file paths. Additional optional
configuration parameters can modify pipeline behavior or set user preferences. 



Requirements
--------------

The GPI Data Pipeline is written in IDL, so all users will need to have a copy
of IDL, either the full IDL program or the IDL runtime environment (which is included as part of the compiled executables). 

The pipeline is supported on IDL version 7.0 or more recent at present, but may
at some future point require IDL 8.  While it may be possible to run some of
the pipeline code on IDL 6, this is not supported.   IDL 8 is recommended.

Mac, Linux and Windows platforms are all supported. There are no particular
dependencies on operating system versions.


