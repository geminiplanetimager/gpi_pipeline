.. GPI DRP documentation master file, created by
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

.. _ifs-data-handbook:

GPI IFS Data Handbook
################################

This document describes the GPI Integral Field Spectrograph (IFS), the
properties of its output data, including various systematics and noise 
sources that one may encounter, and how these data should be calibrated. 
Its goal is to summarize in one place all the properties of GPI data that a new
user should be familiar with to usefully work with the data. 

See also the :ref:`Pipeline User's Guide <user-intro>`, which describes 
the user interface and operation of the software used to process these data.


.. warning::
        This is a WORKING DRAFT document, which is not fully complete and may
        be in error in some places. It represents our current
        understanding of these aspects of instrument performance, and is
        likely to evolve with time. Use your own scientific judgement when
        reducing and analyzing data from GPI. 

Read carefully,
examine your data, evaluate the systematics, and let's find some planets...



Contents
--------

.. toctree::
   :maxdepth: 2

   detector.rst
   fieldofview.rst
   filters.rst
   polarimetry.rst
   pupilcam.rst
   dataformats.rst
   steps/index.rst



.. comment
  Indices and tables
  ------------------
  * :ref:`genindex`
  * :ref:`search`



