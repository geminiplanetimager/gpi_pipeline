Tutorial 4: Spectrophotometric Calibration For Coronagraphic Imaging Spectroscopy
======================================================================================

.. warning::
   Photometric calibration for coronagraphic data can 
   be tricky. There is more than one way to do this. As always users are responsible for
   using their own scientific judgement, checking their results, 
   and not relying solely on the pipeline as a black box. 

   We encourage users to develop their own approaches to accurately calibrating
   their GPI data and assessing the uncertainties and biases. The following is our
   suggestion of one possible approach to photometric calibration.

   Furthermore, as soon as one adds in the complexity of PSF subtraction, 
   that brings a lot of additional complexity in understanding the algorithm throughputs
   and biases of that process. This issue is not described in this brief introduction.


This uses the sat spots, so you have to have measured them first. 


This is RELATIVE calibration - calibrating the companion relative to the
central star. Need to provide the central star's spectral type as a parameter to the Calibrate Photometric Flux primitive. This relies also on the spectral library model in the pipeline, alhtough you can provide your own preferred stelar spectrum if you want. 
Also relies on having the target star magnitude in the FITS header, which should be the case for all GPI science observations, for which this values is provided as an input from the OT. 




Two ways to do this: 

1. On a cube by cube basis, if you can get good S/N on each sat spots. 
   Can only do this for datasets with sufficient S/N. 
2. On combined sequence outputs. 

.. warning:: 
   If you're using non-coronagraphic direct data, it doens't have sat spots
   so the following method doesn't apply. Likewise for polarimetry data the
   calibration is more complex since the spots are extended, and this is not
   yet implemented well. In these cases you can rely on the more traditional
   method of observing a photometric standard star, measuring its counts, and
   deriving a conversion factor from counts/sec to physical units. 


Calibration Cube-by-Cube
--------------------------------

This is the more straightforward way, if you have sufficient S/N to see the sat spots in individual exposures

After making each datacube, use Measure Sat Spots.
Then you can use Calibrate Photometric Flux. This relies on the pre-calibrated
flux ratios of the sat spots for each band. See Wang et al. 2014. 

Then you can combine the cubes in various ways and the calibrations should


Calibration on combined sequences
---------------------------------------

The issue is that if you combine a sequence after derotating to get the 
companion positions to register, then the sat spots smear out, and vice versa. 
So you ahve to reduce 2x.

First take all the input datacubes and combine them WITHOUT rotating, just
using the Combine 3D Datacubes primritive. Median or mean is OK.  Then run the 
Measure Sat Spots on that, save the output datacube with the sat spots info
in the headers. 

Then do a second reduction 
