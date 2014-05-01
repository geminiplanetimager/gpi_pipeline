.. _processing_step_by_step_flat_fielding_lenslets:

Flat Fielding: Lenslet Array Flat 
==================================

.. warning::
   This is one of the areas where algorithms are still in flux and calibration methods are not fully mature.




Observed Effect and Relevant Physics:
---------------------------------------

Differential throughput of lenslets.   
Scattered handful of low throughput lenslets, plus a regular grid pattern due to artifacts from the lenslet manufacturing photolithography. 

.. figure:: fig_flat_fielding_lenslets.png
        :width: 2180 px
        :align: center
        :alt: before and after correction
        :scale: 25%


Pipeline Processing:
---------------------

Use 'Divide by Lenslet Flat Field' primitive with a relevant lensletflat file.

Creating Calibrations:
-----------------------
Currently done via code not yet integrated into the pipeline

Relevant GPI team members
------------------------------------
Marshall Perrin, Patrick Ingraham

