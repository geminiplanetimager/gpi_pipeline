
Recipe Templates
==================

Template recipes are provided for most common data processing tasks, including
analyses of calibration data and science data. In many cases, to reduce your data
you just need to select the relevant FITS files and choose which template recipe
should be applied (or, for common tasks, the :ref:`data_parser` may automatically select the right template for you). 


For convenience, template recipes are divided into several different reduction types:

* :ref:`Spectral Science <spectralscience_templates>`
* :ref:`Polarimetry Science <polarimetryscience_templates>`
* :ref:`Calibration <calibration_templates>`
* :ref:`Testing <testing_templates>`

These different types just provide a convenient way of restricting which subset of
templates are displayed on screen to choose from, based on the recipes that are 
most likely to be of use for the data at hand. [#footnote1]_


.. _spectralscience_templates:

Spectral Science Mode Template Recipes
---------------------------------------


**Quicklook Automatic Datacube Extraction** is used for real-time reductions while operating the instrument. It produces decent quality datacubes without doing the full calibration process

**Create Clean 2D Detector Image** cleans up detector artifacts (dark subtraction, bad pixel repair, etc) but stops before making a datacube

**Simple Datacube Extraction** Currently identical to the **Quicklook Automatic Datacube Extraction**, but future versions will include a flexure corretion, a more thorough noise detector noise reduction, improved extraction algorithm, and a persistence correction

**Calibrated Datacube Extraction** Aimed at performing a science-grade, flux-calibrated, WCS included, data reduction.

**Contrast Measurement** Used to obtain a contrast measurement and evaluate AO performance. This same calculation can also be performed using GPItv

**Simple Extraction, ADI+SSDI reduction** Performs simple reduction and an ADI+SSDI reduction. *This recipe requires testing with on-sky data before being ready for regular use.*

**Simple Extraction, ADI+LOCI reduction** Performs simple reduction and an ADI+LOCI reduction. *This recipe requires testing with on-sky data before being ready for regular use.*


**Rotate and combine extended object** For a simple extraction and ADI reduction of extended objects


.. _polarimetryscience_templates:

Polarimetry Science Mode Template Recipes
-------------------------------------------


**Quicklook Automatic Polarimetry Extraction** is used for real-time reductions while operating the instrument. It produces decent quality datacubes without doing the full calibration process

**Simple Polarization Datacube Extraction** Performs similar extraction to the Quicklook extraction but future versions will include a flexure corretion, a more thorough noise detector noise reduction, improved extraction algorithm, and a persistence correction
 
**Basic Polarization Sequence** performs a basic reduction and computes the Muller matrix, rotates the image such that north is pointed up.



.. _calibration_templates:

Calibration Data Template Recipes
---------------------------------------

Calibration Recipes are discussed in more detail in the :ref:`Step-by-Step guide to processing data<processing_step_by_step>` sections.


.. _testing_templates:

Software Testing Template Recipes
---------------------------------------

This is a section for template recipes that are used in testing and debugging
the pipeline itself. There are several recipes of this type. Don't try to use these for science reductions directly.

.. rubric:: Footnotes

.. [#footnote1] But that said, there is nothing stopping you from choosing to apply a 
                Calibration type template to your science data, or vice versa, if 
                for some reason you wish to do so.

