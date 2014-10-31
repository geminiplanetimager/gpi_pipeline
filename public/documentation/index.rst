
GPI Data Pipeline  Documentation
======================================================


.. _intro:

The Gemini Planet Imager Data Pipeline allows transformation of raw data from
GPI into calibrated spectral and polarimetric data cubes. It also provides some
basic capabilities for PSF suppression through differential imaging, and for
astrometry and spectrophotometry of detected sources.


**Software and documentation by:** Marshall Perrin (STScI), Jérôme Maire
(University of Toronto), Patrick Ingraham
(Stanford), Dmitry Savransky (Cornell), 
Max Millar-Blanchaer (Toronto), 
Schuyler Wolff (JHU),
JB Ruffio (SETI, ISAE), 
Jason Wang (Berkeley),
Zack Draper (U Victoria),
Abhi Rajan (ASU), Naru Sadakuni (UCSC and Gemini),
Michael Fitzgerald (UCLA),
Christian Marois (NRC) ,
and
other members of the GPI Data Analysis Team.  Please see the
:ref:`development credits <sw-credits>` for a complete list of contributors, and the :ref:`release notes <release-notes>` for further details.

**Acknowledging the GPI Pipeline in Publications:** Users of the GPI data pipeline should cite one of the following.
Please also cite appropriate references for `GPI overall <http://adsabs.harvard.edu/abs/2014PNAS..11112661M>`_, the `AO system <http://adsabs.harvard.edu/abs/2014SPIE.9148E..0KP>`_ and `IFS <http://adsabs.harvard.edu/abs/2014SPIE.9147E..1KL>`_, and other aspects of the instrument as relevant.
	
	* `Perrin et al. 2014, 'GPI Observational Calibrations I: Overview of the GPI data reduction pipeline', Proc. SPIE vol. 9147. <http://adsabs.harvard.edu/abs/2014SPIE.9147E..3JP>`_ 
	* `Maire et al. 2010, 'Data Reduction Pipeline for the Gemini Planet Imager', Proc. SPIE vol. 7735 <http://adsabs.harvard.edu/abs/2010SPIE.7735E.102M>`_


You may wish to see :ref:`what's new <release-notes>` in the latest version or jump to the :ref:`quick start tutorial <usage-quickstart>`.

.. admonition:: New Users Start Here

   If you are new to working with GPI data, the following parts of this documentation are good places to start.

   * To install the pipeline, see the :ref:`Installation Manual <installation>`.
   * You can then run through the :ref:`Tutorials <usage-quickstart>`.
   * Then consult the :ref:`Reducing your own GPI data <usage-quickstart-yourdata>` page.
   * To learn more about each step of the data reduction process, consult :ref:`Reducing GPI data Step by Step <processing_step_by_step>`. For more about
     file formats, FITS headers, etc, consult the :ref:`IFS data handbook <ifs-data-handbook>`.


**Getting Help**: The main channel for support of this software is the `Gemini Data Reduction Forum <http://drforum.gemini.edu>`_. Please post questions there
and mark them with the tag `gpi`. Gemini staff and members of the GPI data analysis team monitor that forum to help support the Gemini community in using GPI. You may also wish to consult the :ref:`FAQ <faq>`. Contributions of improvements
to the software or this documentation are very much welcomed. 



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

