
IFS Flexure
==================================

Observed Effect and Relevant Physics:
---------------------------------------

The positions of the individual spectra formed from each microlens are subject to gravitationally induced flexure that affects optical components between the microlens array and science detector on the IFS optical bench. Under normal observational procedure, as the instrument moves in elevation, the flexure is observed to follow standard hysteresis curves with amplitudes of ~0.5 pixels. 

When the instrument is moved outside of it's normal observing range, being above ~80 degrees in elevation or when the cassegrain rotator is in use due to ongoing observations with other instruments, a non-repeatable and unpredictable flexure component is introduced. Although the cause of this has not been confirmed, it is believed to result from an optic or it's mount in the IFS exhibiting micron-level shifts when moved into non-standard positions. Due to the sensitive IFS alignment and the inaccessibility of the suspected optic, it has been decided to compensate for the non-repeatable flexure component in the data reduction software.

Currently, the data reduction pipeline (DRP) corrects for the repeatable component of flexure by adding offsets to the positions of the microspectra that were determined when measuring their wavelength solution (zenith). This is accomplished using a lookup table and the :ref:`Update spot shifts for flexure <updatespotshiftsforflexure>` primitive. In  order to compensate for the non-repeatable component of the flexure, an arclamp image (normally Argon) is taken at either the beginning or end of the observing sequence. This provides a zero point offset to the hysteresis curves. How to implement this offset is discussed below.


Using Flexure Shifts in the GPI Pipeline
--------------------------------------------------

We recommend taking an Argon arc lamp contemporary with each science target for the most precise flexure measurement. (The Gemini instrument scientists will know to do this.) 

- Describe the quick wavelength solution 

Compensating for Flexure:
-----------------------------

When reducing science data, the standard recipes, :ref:`Spectral Science <spectralscience_templates>` contain the "Update Spot Shifts for Flexure" primitive. This primitive allows the user to select between a manual flexure shift, default flexure shifts from a lookup table, and no shifts. If manual flexure shifts are chosen, the x and y shifts are controlled by the manual_dx and manual_dy keywords. The Lookup method requires a calibration file with a 'shifts' extension. This table lists the shifts in x and y as a function of elevation. We recommend beginning with the lookup table option.

If your datacube was reduced with the wrong flexure solution, the datacube will exhibit a checkerboard pattern. The figure below shows a slice of a datacube that used incorrect flexure shifts (1.5 pixels off in both x and y). 

.. figure:: bad_flexure.png
       :width: 400pt
       :align: center

In this case, it is likely necessary to input a manual flexure. To determine the necessary shifts, you should open the raw science frame and overplot the wavelength solution. For information on how to do this see :ref:`Displaying GPI Wavelength Calibration feature <gpitv_wavecal_grid>`. The user may change the position of the overplotted lenslet locations until they line up with the data. Sub pixel position accuracy is possible by eye. 


.. note::
        The x direction shifts are easy to determine by eye, but the ability to determine the shifts in the y-direction can be dependent on the spectral features of your target. 



Relevant GPI team members
------------------------------------
Patrick Ingraham, Marshall Perrin, Schuyler Wolff
