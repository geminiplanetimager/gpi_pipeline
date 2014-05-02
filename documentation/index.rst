
GPI Data Pipeline  Documentation
======================================================


.. _intro:

The Gemini Planet Imager Data Pipeline allows transformation of raw data from
GPI into calibrated spectral and polarimetric data cubes. It also provides some
basic capabilities for PSF suppression through differential imaging, and for
astrometry and spectrophotometry of detected sources.


**Software and documentation by:** Marshall Perrin (STScI), Jérôme Maire
(University of Toronto), Patrick Ingraham
(Stanford), Dmitry Savransky (Cornell), Zack Draper (U Victoria),
Michael Fitzgerald (UCLA),
Christian Marois (NRC) ,
Max Millar-Blanchaer (Toronto), 
Abhi Rajan (ASU), JB Ruffio (SETI, ISAE), Naru Sadakuni (UCSC and Gemini), Jason Wang (Berkeley), Schuyler Wolff (JHU), 
and
other members of the GPI Data Analysis Team.  Please see the
:ref:`development credits <sw-credits>` for a complete list of contributors, and the :ref:`release notes <release-notes>` for further details.

**Acknowledging the GPI Pipeline in Publications:** Users of the GPI data pipeline should cite one of the following:

 * `Maire et al. 'Data Reduction Pipeline for the Gemini Planet Imager', 2010, Proc. SPIE vol. 7735 <http://adsabs.harvard.edu/abs/2010SPIE.7735E.102M>`_
 * Perrin et al. 'Gemini Planet Imager Observational Calibrations I: Overview of the GPI data analysis pipeline', 2014 (in preparation, for SPIE meeting)

**Getting Help**: The main channel for support of this software is the `Gemini Data Reduction Forum <http://drforum.gemini.edu>`_. Please post questions there
and mark them with the tag `gpi`. Members of the GPI data analysis team monitor that forum to help support the Gemini community in using GPI.  Contributions of improvements
to the software or this documentation are very much welcomed.

You may wish to see :ref:`what's new <release-notes>` in the latest version or jump to the :ref:`quick start tutorial <usage-quickstart>`.

.. caution:: 
   This software comes with no warranty nor guarantee of correctness. It represents the GPI
   instrument team's best effort at calibrating and reducing GPI data, but is necessarily a
   work in progress and incomplete. Integral field spectroscopy, polarimetry, and high contrast
   PSF subtraction are complicated, and GPI is a new instrument we are still getting to know
   on sky.  Use your own scientific judgement when analyzing and publishing data from GPI. 



Contents
--------

.. toctree::
   :maxdepth: 1

   installation/index.rst
   usage/index.rst
   gpitv/index.rst
   ifs/index.rst
   developers/index.rst
   faq.rst
   license.rst


Indices and tables
------------------

* :ref:`genindex`
* :ref:`search`

Documentation last updated on |today|

