.. _processing_step_by_step_ipc:

Interpixel Capacitance
==========================

.. seealso:: 

        Further information may be found in `Ingraham et al. 2014 "Gemini Planet Imager Observational Calibrations II:
        Detector Performance and Characterization" <http://arxiv.org/abs/1407.2302>`_
		
		The basic algorithm used here is adapted from `McCullough 2008 "Inter-pixel Capacitance: Prospects for Deconvolution" <http://www.stsci.edu/hst/wfc3/documents/ISRs/WFC3-2008-26.pdf>`_


Observed Effects and Relevant Physics:
---------------------------------------

As in most near-infrared detectors, GPI's H2RG shows signs of interpixel capacitance. IPC is a form of cross-talk that spreads charge from the pixel in which it was collected to the adjacent pixels prior to readout. This is most evident as "crosses" surrounding bright pixels. Cosmic rays and hot pixels will therefore effect a larger percentage of your the array. While obvious in dark frames and point sources, in extended sources IPC can make the Poisson noise appear lower than it really is.


.. figure:: ipc.png
   :align: center
   
   Excerpt of a GPI dark with pixels showing the effects of interpixel capacitance.
   
The tell-tale cross from IPC can be described as the true image :math:`A` convolved with a 3x3 kernel :math:`k`. The sum of all 9 elements in the kernel is 1, with the fraction of capacitance along columns given by :math:`\alpha`, and rows by :math:`\beta`.

:math:`k = \begin{array}{ccc}
0 & \alpha & 0 \\
\beta & 1-2\alpha-2\beta & \beta \\
0 & \alpha & 0 \end{array}`

The observed image is then the true image convolved with the IPC kernel:

:math:`A' = A * k`

The true image can be recovered by performing a Fourier deconvolution:

:math:`F(A') = F(A * k) = F(A)F(k)`

:math:`A = F'(F(A')/F(k))`

Pipeline Processing:
---------------------

The effects of interpixel capacitance can be removed using the pipeline primitive 'Correct for Interpixel Capacitance'. This is currently not included by default in any reduction recipe, but may be added by the user. IPC correction should be done as early as possible. The primitive sets default values for :math:`\alpha` and :math:`\beta` which can be adjusted by the user, if necessary.

.. figure:: ipc_corr.png
   :align: center
   
   The same pixels as above, after correcting for IPC.

Things to watch out for:
-------------------------

The effects of interpixel capacitance may at first appear to be due to charge diffusion. Unlike IPC and other forms of crosstalk, charge diffusion is caused by electrons in the detector migrating to adjacent pixels. Different wavelengths of light will create charges at different depths in the detector. IPC, on the other hand, is not wavelength dependent.
There is also the possibility that IPC in the GPI detector will evolve with time.

Relevant GPI team members
------------------------------------
Douglas Long, Marshall Perrin, Patrick Ingraham