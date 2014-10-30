
.. _polspotcal:

Polarimetric Spot Location Calibration
=========================================

.. admonition:: Published reference

        Further information may be found in `Perrin et al. 2014 "Polarimetry with the Gemini Planet Imager: Methods, Performance at First Light, and the Circumstellar Ring around HR 4796A" <http://arxiv.org/abs/1407.2495>`_


Observed Effect and Relevant Physics:
---------------------------------------

Pipeline Processing:
---------------------

Creating Calibrations:
-----------------------

**Calibration DB File Type:** Polarimetry Spots Cal File

**File Suffix:** polcal

**Generate with Recipe:** 'Calibrate Polarization Spots Locations'


Take a set of flat field observations in polarimetry mode in the filter of interest.  Reduce these
using the 'Calibrate Polarization Spots Locations' recipe and you should be ready to go. 

Typically the same exact set of input data are used for 'Calibrate Polarization Spots Locations' and 
'Create Polarized Flat-field', but two distinct output files are produced from the two recipes. 

.. note::
        This recipe is somewhat computationally intensive, and will take 10-20 minutes to run on typical machines. 

Relevant GPI team members
------------------------------------
Max Millar-Blanchaer, Marshall Perrin
