.. GPI DRP documentation master file, created by
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

.. _gpitv:

GPItv Viewer User's Guide 
################################


This chapter describes how to use the ``gpitv`` graphical data viewer to view your GPI data. 


GPItv is a ds9-like FITS data viewer tool customized for GPI, including display of spectral and polarimetric datacubes and interactive tools for high contrast image analysis such as measuring contrast and performing spectral differencing of cubes.  GPItv provides GPI observers with both a simple
means for cursory "quick look" data analysis in real time at the telescope,
plus a set of tools for viewing and manipulating GPI data during
post-observing scientific analyses.  


GPItv is a heavily customized derivative from ATV, the well-known DS9-like
display tool for astronomical images in IDL (Barth et al. 2001;
http://www.physics.uci.edu/~barth/atv/), with much new functionality
developed specifically for GPI.  Anyone familiar with using ATV,
SAOimage or DS9 will get used to GPItv very quickly.  


.. warning::
        Screen shots not yet ported into this HTML documentation. 

Acknowledgements
--------------------

GPItv is based on `atv by Aaron Barth et al.
<http://www.physics.uci.edu/~barth/atv/>`_   The Header Viewer dialog in gpitv
is taken from the `OSIRIS Quicklook tool
<http://www2.keck.hawaii.edu/inst/osiris/tools/>`_ ``ql2``, itself derived from
the NIRC2/NIRspec quicklook. The "Browse Files" dialog is based upon code
derived from David Fanning's tool `selectimage.pro
<http://www.idlcoyote.com/programs/catalyst/source/applications/selectimage.pro>`_. 




Contents
--------

.. toctree::
   :maxdepth: 2

   intro.rst
   getting_started.rst
   examples.rst
   features.rst
   options.rst


.. comment
  Indices and tables
  ------------------
  * :ref:`genindex`
  * :ref:`search`



