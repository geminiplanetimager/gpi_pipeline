
Saturation and Nonlinearity
============================

Observed Effect and Relevant Physics:
---------------------------------------

The sensitivity of a given pixel is a function of the fraction of its well depth which is filled. Although the full-well depth of the detector is 116,000 electrons (corresponding to ~38000 ADU using a gain of 3.04 electrons/ADU), the detector begins to have a non-linear response at the ~1% level when the well depth is ~16000 ADU (or ~49 000 electrons). It should be noted that the linearity response of the detector was performed for a different gain and with the detector readout electronics tuned differently then they are presently. 

Until a new linearity measurement can be performed, users are advised to keep the pixel intensities below ~16000 ADU. 

.. note::
    Updating these measurements is a work in progress as of 2014A. Consult Naru Sadakuni for details.


Pipeline Processing:
---------------------
At this time there is no primitive to apply a non-linearity correction in the pipeline. Instead there is support for correcting 
nonlinearity in real time during the detector readout (this is a better approach since it enables the correction to be used when
deriving the slope from the up-the-ramp readout.) The expectation is that once we have a better calibration of this, we will enable
this correction on the detector server. 

Relevant GPI team members
------------------------------------
Patrick Ingraham, Naru Sadakuni

