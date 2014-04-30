
IFS Flexure
==================================

Observed Effect and Relevant Physics:
---------------------------------------

The lenslet positions on the detector are subject to gravitationally induced flexure. During the course of an observation, the shifts vary in a repeatable way with elevation. However, large shifts of several pixels occur when the GPI rotates around the ___ axis, when other Gemini instruments are in use. In order to properly perform the spectral subtraction, we must compensate for this flexure.

Using Flexure Shifts in the GPI Pipeline
--------------------------------------------------

We recommend taking an Argon arc lamp contemporary with each science target for the most precise flexure measurement. (The Gemini instrument scientists will know to do this.) 

- Describe the quick wavelength solution 

Compensating for Flexure:
-----------------------------

When reducing science data, the default recipe, :ref:`<>` contains the "Update Spot Shifts for Flexure" primitive. This primitive allows the user to select between a manual flexure shift, default flexure shifts from a lookup table, and no shifts. If manual flexure shifts are chosen, the x and y shifts are controlled by the manual_dx and manual_dy keywords. The Lookup method requires a calibration file with a 'shifts' extension. This table lists the shifts in x and y as a function of elevation. We recommend beginning with the lookup table option.

If your datacube was reduced with the wrong flexure solution, the datacube will exhibit a checkerboard pattern, see figure. 

.. figure:: bad_flexure.png
       :width: 400pt
       :align: center

In this case, it is likely necessary to input a manual flexure. To determine the necessary shifts, you should open the raw science frame and overplot the wavelength solution. For information on how to do this see :ref:`Displaying GPI Wavelength Calibration feature <gpitv_wavecal_grid>`. The user may change the position of the overplotted lenslet locations until they line up with the data. Sub pixel position accuracy is possible by eye. 


.. note::
        The x direction shifts are easy to determine by eye, but the ability to determine the shifts in the y-direction can be dependent on the spectral features of your target. 



Relevant GPI team members
------------------------------------
Patrick Ingraham, Marshall Perrin, Schuyler Wolff
