Darks
=========

Observed Effects and Relevant Physics:
---------------------------------------

Like all IR detectors, the Hawaii 2-RG detector in GPI has nonzero dark current. Typical values are much less than 1 count per second per pixel, but some "hot" pixels have much higher dark rates. 
For GPI, dark files operate in the typical manner for IR detectors and are used to subtract dark current, the detector bias, and other background (e.g. light leaks) from types of science and calibration observations. Darks are taken by setting the Lyot stop to Blank (an opaque mask). Because of the possible presence of various nonlinear detector effects (saturated hot pixels, reset anomaly, etc), it is generally considered better to use a reference dark that is relatively similar in integration time.  

The GPI team and Gemini have established a standard set of dark integration times ranging from 1.5 s to 300 s in steps of ~3x. These are taken periodically (planned to be weekly) and
are taken with enough coadds and exposure to achieve good S/N. (Coadds increase efficiency for short integration times. 10 coadds * 10 exposures is a recommended approach. )

.. note::

   Typical observations with GPI will be hour-long sequences of exposures. For these to not be systematically limited by the dark frame that is identically subtracted from each individual exposure, that dark frame must be significantly deeper than your science observations. You probably will want to take several hours of darks.


Periodic dark observations taken during GPI I&T at UCSC show that the detector's complement of hot pixels evolves slightly but noticeably on two week timescales. Using darks more than a week or two different in time from your science data results in visibly more residual hot pixels in the final datacubes. (The dark current for the large majority of normal pixels is in comparison very stable, as are indeed most of the hot pixels - only some outliers have been observed to evolve.)

Artifacts observed in dark frames but specifically addressed in other sections section include: :doc:`badpixels`, :Doc:`destriping_and_microphonics` and :doc:`persistence`.  Regions of elevated dark current are visible near the detector corners in deep exposures, due to scattered light within the IFS leaking around the detector housing baffle, but the count rates here are still very small.


**Light leak:** There is a very low level light leak visible in 3 corners of the detector, where light is leaking around a small gap in the detector housing between the detector itself and the field flattener lens. This is visible on high S/N long exposure darks, but in practice has completely negligible impact on science. 

.. figure:: dark-S20130419S0490.jpg
       :width: 400pt
       :align: center

       Example dark image. This is a 120 s dark, shown on a log stretch from 0-0.05 counts/second. The median dark count rate for normal pixels is negligible, ~ 0.006 counts/sec/pixel. The 
       brighter regions in three corners are due to light leaks around the IFS detector housing. This stretch highlights them but in fact they are very faint, with a 
       peak count rate ~ 0.03 counts/sec/pixel.  Many scattered hot pixels are visible across the field.  In practice only these hot pixels are likely to significantly 
       affect your GPI data. The dark count in typical good pixels and even the light leak regions is just too small to have an impact.

Using Darks in GPI Pipeline Reduction:
------------------------------------------

Most data reduction recipes for raw GPI data will begin by subtracting a dark frame using the pipeline primitive :ref:`Subtract Dark Background <SubtractDarkBackground>`. Typically that dark is obtained automatically from the :ref:`Calibration Database <calibdb>` based on the closest-in-time dark file with a matching integration time.  There are no significant user-selectable options for this step to be concerned with.


.. note::

  The GPI data pipeline will search for the closest-in-time available darks, and
  from those find the one with the closest match in exposure time. The dark counts
  will be rescaled by the ratio of integration times to match the science image. 
  
  By default it
  will allow scaling exposure up or down by a factor of 3x; if no darks are found
  within that range an error will be raised.  This is a very conservative approach and 
  you may find that good results can be obtained with larger scalings. The threshold can 
  be adjusted in the  :ref:`Subtract Dark Background <SubtractDarkBackground>` primitive's arguments. 



Creating Calibrations:
-----------------------
**Generate with Recipe:** "Dark"

**Calibration DB File Type:** Dark

**File Suffix:** dark

To create dark calibrations, take a set of many dark files (with the Lyot set to Blank). As mentioned above, ideally one would want enough images (typically > 100) to ensure that noise in the reduced darks is a order of magnitude less than noise in the science frames, but that will not always be feasible.  Process them using the "Dark" recipe found the Calibration reduction section.

Repeat the above process for all exposure times of interest. For large numbers of integration times, this is most easily accomplished using the Data Parser to generate suitable recipes .

Dark frames are also used to determine hot pixels. This is described further in the :doc:`badpixels` section. 


What to Watch Out For
---------------------------------
The standard pipeline processsing to create dark frames is a straightforward process involving 2 steps:

 1. Destripe and remove microphonics
 2. Combine 2d images

The image below shows the three dominant artifacts seen in dark images. The solid red circles show the regions where the majority of the microphonics is observed. The dashed green line shows examples of strong channel bias offsets (32-pixel wide vertical stripes). The dotted purple lines indicate regions of large horizontal striping. These effects, discussed in detail in :doc:`destriping_and_microphonics`, are removed using the :ref:`Aggressive destripe assuming there is no signal in the image. (for darks only) <Aggressivedestripeassumingthereisnosignalintheimage.(fordarksonly)>` primitive.

.. image:: raw_dark_mod.png
        :scale: 50%
        :align: center

The 2-d files are then combined using a median or mean, using the :ref:`Combine 2D images <Combine2Dimages>` primitive. A reduced stack of 30-1.5 second dark images is shown below. 

 .. image:: reduced_dark.png
        :scale: 50%
        :align: center

The remaining artifacts are bad-pixels, seen as the white pixels and small channel bias offsets. At the moment, no channel bias correction is performed, but the noise from the offsets is seen to reduce by the square root of the number of detector reads.

Note that no persistence is present in the above images. If persistence is present in the darks, it can be attenuated by inserting the 'Remove Persistence' primitive after the destripe primitive. Persistence is discussed in detail in the :doc:`persistence` section.

Relevant GPI team members
------------------------------------
Marshall Perrin, Patrick Ingraham, Naru Sadakuni
