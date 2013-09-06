Darks
=========

Observed Effects and Relevant Physics:
---------------------------------------

Like all IR detectors, the Hawaii 2-RG detector in GPI has nonzero dark current. Typical values are much less than 1 count per second per pixel, but some "hot" pixels have much higher dark rates. 
For GPI, dark files operate in the typical manner for IR detectors and are used to subtract dark current, the detector bias, and other background (e.g. light leaks) from types of science and calibration observations. Darks are taken by setting the Lyot stop to Blank (an opaque mask). Because of the possible presence of various nonlinear detector effects (reset anomaly, etc), it is generally considered safest to take specific individual dark frames for each integration time you use, rather than taking just one integration time and rescaling it. Because the dark frame is subject to read noise, like all other observations, the observer should ensure that an equal number of dark frames and science frames are performed. Coadds increase efficiency for short integration times. 10 coadds * 10 exposures is a recommended approach. 

.. note::

   Typical observations with GPI will be hour-long sequences of exposures. For these to not be systematically limited by the dark frame that is identically subtracted from each individual exposure, that dark frame must be significantly deeper than your science observations. You probably will want to take several hours of darks.


Periodic dark observations taken during GPI I&T at UCSC show that the detector's complement of hot pixels evolves slightly but noticeably on two week timescales. Using darks more than a week or two different in time from your science data results in visibly higher residual hot pixels in the final datacubes. (The dark current for the large majority of normal pixels is in comparison very stable, as are indeed most of the hot pixels - only some outliers have been observed to evolve.)

Artifacts observed in dark frames but specifically addressed in other sections section include: :doc:`badpixels`, :Doc:`destriping_and_microphonics` and :doc:`persistence`.  Regions of elevated dark current are visible near the detector corners in deep exposures, due to scattered light within the IFS leaking around the detector housing baffle, but the count rates here are still very small.


.. figure:: dark-S20130419S0490.jpg
       :width: 400pt
       :align: center

       Example dark image. This is a 120 s dark, shown on a log stretch from 0-0.05 counts/second. The median dark count rate for normal pixels is negligible, ~ 0.006 counts/sec/pixel. The 
       brighter regions in three corners are due to light leaks around the IFS detector housing (specifically the gap between the IFS field lens baffle and the detector itself). This stretch highlights them but in fact they are very faint, with a 
       peak count rate ~ 0.03 counts/sec/pixel.  Many scattered hot pixels are visible across the field.  In practice only these hot pixels are likely to significantly 
       affect your GPI data. The dark count in typical good pixels and even the light leak regions is just too small to have an impact.

Using Darks in GPI Pipeline Reduction:
------------------------------------------

Most data reduction recipes for raw GPI data will begin by subtracting a dark frame using the pipeline primitive :ref:`Subtract Dark Background <SubtractDarkBackground>`. Typically that dark is obtained automatically from the :ref:`Calibration Database <calibdb>` based on the closest-in-time dark file with a matching integration time.  There are no significant user-selectable options for this step to be concerned with.


.. note::

  Currently the GPI pipeline adopts a very conservative approach of only using
  dark frames taken with exactly the same integration time as a given science
  frame. This allows direct subtraction without rescaling for any nonlinear
  behavior of pixels, such as can sometimes be seen for some hot pixels. 

  However, tests have shown that for the vast majority of pixels, scaling darks
  from different exposure times by the ratio of the integration times and then
  subtracting those, pretty much works fine. The conservative "library of darks
  at all distinct integration times" approach has been retained, in part simply
  because it's simple and low cost to take darks often when the instrument is
  not in use. 



Creating Calibrations:
-----------------------
**Generate with Recipe:** "Dark"

**Calibration DB File Type:** Dark

**File Suffix:** dark

To create dark calibrations, take a set of many dark files (with the Lyot set to Blank). As mentioned above, ideally one would want enough images (typically > 100) to ensure that noise in the reduced darks is a order of magnitude less than noise in the science frames, but that will not always be feasible.  Process them using the create Dark file recipe found the Calibration reduction type.

Repeat the above process for all exposure times of interest. For large numbers of integration times, this is most easily accomplished using the Data Parser. It can be used to generate suitable recipes when provided with one or more sequences of dark files.

Dark frames are also used to determine hot pixels, this is described further in the :doc:`badpixels` section. 


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
