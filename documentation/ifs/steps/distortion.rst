
Astrometric Calibration and Distortion Correction
===================================================

.. seealso:: 

        Further information may be found in `Konopacky et al. 2014 "Gemini Planet Imager Observational Calibrations V:
        Astrometry and Distortion" <http://arxiv.org/abs/1407.2305>`_


This page still to be written. 

Information on astrometric performance of GPI can be found at http://www.gemini.edu/sciops/instruments/gpi/instrument-performance?q=node/12165 and in the above reference.


Observed Effect and Relevant Physics:
---------------------------------------

Pipeline Processing:
---------------------

Distortion is small, with an average positional residual of 0.26 pixels over the field of view, and can be corrected using a 5th order polynomial. See the :ref:`CorrectDistortion` primitive.


Creating Calibrations:
-----------------------

The distortion was calibrated in the lab by the GPI team. Instrument users should not need to rederive this calibration on their own, but should `download the relevant calibration file from Gemini <http://www.gemini.edu/sciops/instruments/gpi/public-data>`_. 

Relevant GPI team members
------------------------------------
Quinn Konopacky, Jerome Maire, Sandrine Thomas, Mike Fitzgerald, Pauline Arriaga

