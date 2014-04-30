.. _usage-quickstart_pol:

Tutorial 3: Polarimetry data reduction 
#####################################################

This is a quick tutorial to help new users familiarize themselves with reducing polarization data sets with the GPI pipeline. It assumes that you have at least glanced at the **General Reduction Method** in the :ref:`_usage-quickstart`. 

We try to keep the tutorial as general as possible, so that it can be used as a guide for general pol reductions, but it has been designed for use with the sample data set. 


Getting the Sample Dataset for this Tutorial
=================================================

A sample polarization dataset can be found `here <http://docs.planetimager.org/GettingStarted_pol_tutorial_dataset>`_. 

The directory contains a number of different GPI file types: 
	* Dark File - S20130912S0017-dark.fits
	* Bad Pixel Map - S20131208S0020_badpix.fits
	* Microphonics Model -  S20131117S0172_microModel.fits
	* GCAL K1 Flat - S20131212S0043.fits to S20131212S0045.fits 
	* Science Images - S20131212S0320.fits to S20131212S0323.fits

Download these files and place both the bad pixel map and dark file into your GPI calibrations folder. Open the GPI Data Pipeline and in the GPI DRP Status Console window click the **RESCAN CAL DB** button. This registers your new files in the calibration file database, and will allow the pipeline to find them automatically. If you do not do this step you will run into errors. 

.. Note:: The creation of the dark file and the bad pixel map are not covered in this tutorial, but you can see how to create your own dark files from  the :ref:'_usage_quickstart'. 



Making a Polarization Spot Calibration File
============================================================
In GPI's polarization mode each lenslet creates a pair of spots on the detector plane: one for each orthogonal polarization state. A polarization spot calibration file tells the data pipeline where to find the two spots corresponding to each lenslet. Creating a polarization spot calibration file is done in much the same way as a wavelength calibration file for spectral mode. 
	1. Open the recipe editor and press the Add Files button. Select flat files taken in the same GPI filter band as your science data. In the tutorial data set select files **S20131212S0043.fits to S20131212S0045.fits**. 
	2. In the Recipe Editor, from the drop down menus on the right select **Reduction Category -> Calibrations** and then **Recipe Template -> Calibrate Polarization Spot Locations - Parallel**. By selecting the Parallel option by default the pipeline tries to spread the computation across 4 threads. If for some reason you'd rather limit the process to one thread can can choose Calibrate Polarization Spot Locations. 
	3. Press Save Recipe and Queue. This process should take a few minutes, depending on your machine and whether or not you chose the parallel option. 
	4. Once this is complete it's a good idea to double check that your spot calibration file is doing what it should. Open GPItv and open the raw data file. From the **Labels** menu select **Labels -> Get Wavcal/Polcal from CalDB**. Now select **Labels-> Plot Wavecal/Polcal Grid**. 
 
	   When zoomed out it your calibration should looked like a nice evenly spaced grid: 

		.. image:: good_polspot_cal.png
			:scale: 75%
			:align: center

	   If your calibration looks like this: 

		.. image:: bad_polspot_cal.png
			:scale: 75%
			:align: center
 
	   then something has gone wrong. This is often a sign of poor bad pixel correction. Double check that you have an up-to-date bad pixel map. If the problem persists then you can start tweaking the options in the Parallelized Polarzation Spot Calibration primitive. Details on this requires an advanced understanding of how the pol spot locations are extracted and is not covered in this tutorial. 

	   When you zoom in, the calibration should connect lenslets spots together via a grid of red lines, and join two orthogonal polarization states with green lines: 

		.. image:: good_polspot_cal_zoom.png
			:scale: 75%
			:align: center

	   The green line indicates a polarization spot pair from the same lenslet. 

	5. To check that the spots have been matched correctly look for a low throughput lenslet. In K1, one can be found roughly at [1915,1339] detector coordinates. The two dim spots should be connected with a green line: 

		.. image:: low_throughput_polcal.png
			:scale: 75%
			:align: center

	   If the spots are not lined up then you will have to adjust the **centrXpos** and the **centrYpos** primitive parameters for the Parallelized Polarization Spot Calibration, so that the centre fall on an adjust pixel. More details of how to choose this well are not within the scope of this tutorial. 

	   If all is well then you have successfully created your polarization spot calibration file. It has automatically been added to your calibration database. You are ready to begin reducing your data. 


Creating Polarization Data Cubes (podc files)
============================================================
This step will walk through how to create polarization data cube from raw data. A polarization cube is a 3D data cube, where the third dimension holds two slices: one for each polarization orthogonal state measured at the detector plane. 

	1. In the Recipe Editor press the Add Files button and choose your Data Files. For the tutorial dataset this will be files **S2013S0320.fits to S2013S0323.fits**.
	2. Select **Reduction Category-> PolarimetricScience** and **Recipe Template -> Simple Polarization Datacube Extraction**.
	3. Because of flexure effects internal to GPI it is possible that your Pol Spot Calibration files will not properly reflect the locations of the Polarization spots in your science frame. To check this open GPItv and open one of your raw science images. Plot the Polcal spot locations as we did in Step 4 of creating our wavecal.   

	   If there are flexure effects present then you will see the spot calibration misaligned from the spot centers: 

		.. image:: bad_flexure_alignment_pol.png
			:scale: 75%
			:align: center

	   At this point you should estimate (by eye) the offset [dx,dy] between the spot calibration and the centres of the pol spots. It should be on the order of 1 pixel or less. In the most extreme cases you might have offsets of up to 3 pixels. For the tutorial dataset the offsets are approximately [dx,dy]=[-0.9,0.6]. 

	4. Return to the Recipe Editor window, and select the primitive named "Update Spot Shifts for Flexure". Change the Value of the method Parameter  to "manual". Enter your estimated [dx,dy] in the manual_dx and manual_dy Parameters. Don't forget to press ENTER after changing primitive parameter values. 

	   Your Recipe Editor Window should now look something like this: 

		.. image:: recipe_editor_pol1.png
			:scale: 75%
			:align: center 

	5. Now Press "Save Recipe and Queue". The pipeline should create 4 files with suffixes "_podc". The pipeline has created one image for each orthogonal polarization. You can now view your podc files in GPItv (a window should have popped open automatically).

	   You can view the total intensity (the sum of the two images) or the difference of the polarization, by selecting either option in the drop down menu highlighted in red:
		.. image:: gpitv_podc.png
			:scale: 75%
			:align: center

	   Here you may notice a Moiré pattern in the data. This is typical of K1 data and is an artifact of the extraction procedure. Do not fear, it will get removed later on during the double differencing. 

Creating Stokes Cubes from Polarization Cubes
============================================================

	1. In the Recipe Editor press the Add Files button and select your newly created podc files. A standard polarization sequence has at least four rotations of the half-wave plate, rotating from 0 degrees to 67.5 degrees in 22.5 degree increments, though many observing sequences will have have more. For the tutorial you should add the files named: **S20131212S0320_podc.fits to S20131212S0323_podc.fits**.

	   If you are unsure where they have been saved, the GPI DRP Status Consol provides the path of the last saved file. 

	2. Select **Reduction Category-> PolarimetryScience** and **Recipe Template -> Basic Polarization Sequence (from podc cubes)**. 

	3. An important step in the combining a polarization sequence is rotating the images to the same position angle. This is done by the Rotate North Up primitive, which looks for the pivot point of the rotation in the header keywords [PSFCENTX, PSFCENTY]. These keywords are created by the Measure Star Position for Polarimetry primitive. This primitive relies on an estimate of the centre position, found as a primitive parameter. Open one of your podc files in GPItv and estimate the location of the centre of the occulting spot. For the tutorial dataset the centre is roughly at [147,147]: 
		
		.. image:: gpitv_psfcent.png
			:scale: 75%
			:align: center

	   Enter these values into the Measure Star Position for Polarimetry primitive. Your recipe editor should now look roughly like this:
		.. image:: recipe_editor_pol2.png
			:scale: 75%
			:align: center

	4. Presss "Save Recipe and Queue" and wait for the pipeline to process your files. The result will be a fits file with a _stokesdc suffix. 

	5. Your final file will have four polarization slices, each corresponding to one Stokes parameter. You can flip through the slices using the selection bar in GPItv: 
		
		.. image:: gpitv_slider.png
			:scale: 75%
			:align: center		

	   You can also view the linear polarized intensity or the linear polarized fraction by selecting them in the drop down menu. Keep in mind that the polarized fraction is calculated using the Stokes I slice, which has not been PSF subtracted,  and so will only provide you with an upper limit to the actual linear polarized fraction. 

	6. You can plot polarization vectors from the Labels menu: Labels -> Polarimetry. The dialog box provides you with a number of options. 
	   
	   You may mask out vectors based on simultaneous minimum and maximum values of both the polarized intensity and polarized fraction. For example: 
		.. image:: gpitv_pol_box.png
			:scale: 75%
			:align: center

		.. image:: gpitv_polvec.png
			:scale: 75%
			:align: center


Creating Stokes Cubes from Raw Data
===========================================

	1. If you are confident that you have a good estimate of the star's location you can create a Stokes Data Cube in one step by selecting Recipe Template -> Basic Polarization Sequence (from Raw Data). 

	2. Enter the offsets due to flexure as parameters to the "Update Spot Shifts for Flexure" primitive. 

	3. Enter the estimate of the star's coordinates as parameters to the "Measure Stay Position for Polarimetry" primitive. 

	4. Press "Save Recipe and Queue"


