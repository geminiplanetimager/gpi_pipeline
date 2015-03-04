
.. _ifs_data_gallery:

A Gallery of Example Data, Artifacts, and Noise Sources to be Aware Of
===========================================================================


This page is intended as a guide to some of the oddities 
that may occasionally crop up in GPI data. Its goal is to 
help users understand the physical origins of phenomenology seen in
GPI spectral and polarimetric datacubes, and to what extent
the data pipeline can help mitigate any given artifact (or not). 

Anatomy of a GPI Coronagraphic PSF
---------------------------------------

This is what your data *ought* to look like...

Example PSFs for each filter under decent conditions? 

.. image:: badimg_01_Good_Hband.png
        :scale: 75%
        :align: center

Butterfly from wind

.. image:: badimg_02_Buttefly.png
        :scale: 75%
        :align: center


Artifacts from AO, Coronagraph, and Telescope Systematics
----------------------------------------------------------


Misaligned coronagraph

.. image:: badimg_03_MisalignedMask.png
        :scale: 75%
        :align: center

Bad AOWFS darks

.. image:: badimg_04_WFSBias.png
        :scale: 75%
        :align: center

Misaligned observatory dome

.. image:: badimg_05_Dome.png
        :scale: 75%
        :align: center

37 Hz secondary vibration

.. image:: badimg_06_37Hz.png
        :scale: 75%
        :align: center

Star temporarily moving from behind mask

.. image:: badimg_07_Peeking.png
        :scale: 75%
        :align: center


Artifacts from IFS and Detector Systematics
-----------------------------------------------

Microphonics vibration


Persistence
spec into pol, pol into spec, flat field into data, etc. 


Lenslet 30x50 grid

.. image:: badimg_08_LensletGrid.png
        :scale: 75%
        :align: center

Artifacts from Data Pipeline Systematics
-----------------------------------------

Moire from datacube assembly

.. image:: badimg_09_Moire.png
        :scale: 75%
        :align: center


