.. _usage-quickstart:

Quick Start: Diving into data reduction
########################################


This is a quick tutorial to help new users get familiar with the GPI pipeline. More detailed
documentation of the tools shown here can be found on subsequent pages. 

Sample Data Reduction Tutorial
==============================

As an introduction to reducing data with the GPI Pipeline, a simple set of data is available on the Canadian Astronomy Data Center (CADC). If it is the first time you visit CADC, you will need to `register <http://www.cadc-ccda.hia-iha.nrc-cnrc.gc.ca/auth/register.html>`_. Once it is done, go into the gpi directory and download the **GettingStarted_tutorial_dataset** folder.
This contains a small set of data to give an overview of the different types of image and how to process them. All the files are raw data coming from the detector and we will reduce them one at a time.

        
The GPI Pipeline GUIs
==============================

It is assumed you have successfully launched the pipeline following the previous sections.(If not, see the :ref:`installation` manual.) Therefore, you should have the two IDL sessions opened with the GPI launcher GUI and the GPI DRP status console below. 
See :ref:`first-startup` and :ref:`starting_pipeline`.
The GPI pipeline console should indicate something like::

|    Now polling for DRF files in /Users/yourusername/somedirectory/GPI/queue/

The launcher window
---------------------
The Launcher is a little menu window that acts as the starting point for launching other tools. 
In this getting started tutorial, we will only use **GPItv** and the **Recipe Editor** tools.

.. image:: GPI-launcher.png
        :scale: 50%
        :align: center
        
The Status Console
---------------------
This lets you see the current execution status, view log messages, and control certain aspects of the pipeline. 
See :ref:`status_console` for more details.

.. image:: GPI-DRP-Status-Console.png
        :scale: 75%
        :align: center


Contents of the Sample Dataset
==============================

.. image:: GPI-TV-steps.png
        :scale: 75%
        :align: center
        
Before reducing any files, the best is probably to take a look at the raw data we have using GPItv.
Click on the GPItv button on the GPI launcher to open it (See :ref:`gpitv` for more details):

  1.  Then **File->Browse Files...**, 
  2.  In the new window push the button **Change...** and select a folder in the **GettingStarted_tutorial_dataset**. 
  3.  The **.fits** files list should appear. 
  4.  As you select one file or another, the GPItv window should refresh and plot the new image. 
  5.  Use the GPItv menu **File->View FITS headers...** to get detailed information for each image.
  6.  Click on the image to center the view on a pixel. Adapt the zoom with the buttons.

Feel free to experiment with the GPItv GUI and try out different functions. Most concepts should be straightforward to anyone familiar with `ds9 <http://hea-www.harvard.edu/RD/ds9/site/Home.html>`_ or especially `atv <http://hea-www.harvard.edu/RD/ds9/site/Home.html>`_. 


Description and preview
--------------------------

* The two folders called **darks4_36s** and **darks58_19** contain both darks images with different integration times (respectively 4.36 s and 58.19 s [#footnote1]_ ). Darks files are not thrilling to see but here is an example. We can see horizontal stripes caused by correlated noise from bias drifts during detector readout. They will be removed by the pipeline.

.. image:: dark.png
        :scale: 50%
        :align: center

* **Wavelength_cal** contains Xenon arc lamp calibration data. These images are much more interesting because you can observe particular wavelength positions for the lenslets. These data are used to calibrate the wavelength solution for each of the different lenslets.  Given the orientations of IFS spectral prism and detector, shorter wavelengths are closer to the top of the detector for each lenslet (i.e. have higher Y pixel values) while longer wavelengths extend down toward the bottom. 
        
.. image:: Xe-lamp.png
        :scale: 50%
        :align: center

       
* **Science** contains the raw data that we really want to reduce. This is 2D raw data in spectral mode of a coronagraphic occulted source.  Each lenslet spot is a unique in the sky and the spectra data are all dispersed. The pipeline will correct and transform this image in a more readable data cube where each slice corresponds to a wavelength.         

.. image:: science.png
        :scale: 50%
        :align: center
        

.. rubric:: Footnotes

.. [#footnote1] 
  The reason for these odd exposure times is that GPI IFS exposures are quantized in units of the readout time for the detector, 1.455s. These darks thus represent 3 readout times and 40 readout times, respectively. Because of this quantization, in practice one typically just rounds the durations, so these would be e.g. "4.5" and "58" s exposures - there's no need to carry around all the significant figures. 



General reduction method
==============================

Let's first give the general method to reduce any file. This will then be applied in the next sections for different particular cases. Only the selected items in the different option lists will change.

Press the **Recipe Editor** button in the GPI Launcher window and the window below will open.

.. Note:: The principle of the pipeline is based on recipes to reduce files. A recipe includes a list of input files (the ingredients) and a list of primitives to be applied on those files (the actions). Each primitive is an elementary algorithm to be applied on files listed in the recipe. The action can be anything, for instance subtract dark frame or build data cube. There are two kinds of primitives: ones that should be applied on each file and ones that are applied on all files together. For instance, **Subtract Dark** acts on one file at a time, while **Combine 2D images** will merge all the files from the list resulting in a single output file. The special primitive **Accumulate Images** divides the two categories of primitives.  All the primitives before are applied to each file, then Accumulate Images gathers up the results, and any primitives after are applied to the entire set.

.. image:: recipe-editor-steps.png
        :scale: 75%
        :align: center
        
The numbers of each of the following steps match with the screenshot above.

1)	Press the upper-left button **Add File(s)** and select the files to reduce.
2)	The selected files should appear just below.
3)	Select the reduction type in the menu.
4)	Select a Recipe Template. You may want to change the recipe if it doesn't match exactly to your expectation. It is possible to add, move and remove any primitive and also to change various input parameters that adjust algorithm details.
5)	Press **Save Recipe and drop in queue** button. This will generate the recipe based on the selected files and the list of primitives. The recipe is automatically saved in the queue directory, meaning that it will be read as soon as the pipeline is idle. The reduction might take a while depending on the computer.

In the following, these steps will be repeated several times with specific indications. 

.. note:: 
	For every reduction, a gpitv window will open with the result of the reduction and the file will be saved in the reduction folder defined when installing the pipeline. If you don't want to plot or to save the results, you can change the parameters **Save** and **gpitv** of the primitives.
	To change parameters, select the primitive in the upper right table. Then, its parameters will appear in the bottom right table. Select the value of the parameter and type what ever is asked. Finally, press enter to validate the input.

.. 
	note:: The recipe templates often only work in a particular context, meaning that if you try to apply one of them to a random file it probably won't work and the pipeline may crash. It is because the primitives are yet not very robust and they need more or less exactly the inputs they were designed for.


Reduce your calibration and Science files
=========================================

Darks
--------------------

The dark calibration files for a given integration time can be combined using these amendments to the Recipe Editor usage steps above:

- **For step 1)** Select the darks with 58.19s integration time: **S20130125S0201(-210).fits**.
- **For step 3)** Choose the **Calibration** Reduction type.
- **For step 4)** Choose the **Dark** Recipe template.

- **Redo this with the 2.91s integration times** which corresponds to **SO20130123S0301(-310).fits**.  Use the button **Remove All** to remove all the selected files.

The selected primitives are then:

- Aggressive destripe (assuming there is no signal in the image): This should remove the apparent lines in the image that come from the readout of the pixels by the detector.
- Accumulate Image: Gather all the images of the recipe. It indicates that the subsequent primitives will apply to all images.
- Combine 2D dark images: Merge all the images with the same integration time using the median.

The GPI DRP Status Console will display a progress bar and  log messages while reducing the files.


When reducing calibration files the result is automatically saved in the Calibrations folder. The path to this folder was defined when installing the pipeline and should normally be in the reduced folder (See :ref:`configuring` ``$GPI_REDUCED_DATA/calibrations``).

The pipeline will look for calibration files automatically by reading the text file **GPI_Calibs_DB.txt** in the calibration folder (see :ref:`calibdb`). There is a button at the bottom of the **GPI DRP Status Console** called **Rescan Calib. DB** to create or refresh this text file. 



Wavelength solution
--------------------

As for the darks, the wavelength solution calibration files can be created using the Recipe Editor reduction steps with the following additions:

- **For step 1)** Select Xe-arc lamp files: **S20130122S0101(-105).fits**. 
- **For step 3)** Keep selected the **Calibration** reduction type.
- **For step 4)** Choose the **Wavelength Solution** Recipe template.

.. note:: The sample files provided contain neither a Thermal/Sky background calibration file, nor bad-pixel maps so you will get warnings but it should work anyway. How to create such files is described `later in this documentation <processing_step_by_step>`

.. 
	note:: The calibration fails a little on the upper left corner because of lacking corrections (see previous note). But it is acceptable yet as this tutorial is only an introduction.

A sample of the 2D image with the computed calibration is given below. The green lines are the locations of the individual lenslet spectra. The coordinates of the lenslets are stored in a .fits file cube in the **calibrations** folder. Use GPItv to take a look to the result.

.. image:: wavelength-solution.png
        :scale: 100%
        :align: center

Reduce your science data
==============================

Here again the method is the same.

- **For step 1)** Select your science data **S20130125S0091.fits**.
- **For step 3)** Select the **SpectralScience** reduction type.
- **For step 4)** Choose the **Quicklook Automatic Datacube Extraction** Recipe template.

All the calibration files are automatically found and the result is a final data cube. The result should be plotted in GPItv at the end of the reduction. Feel free to look at the different wavelengths by changing the selected slice.

.. image:: data-cube.png
        :scale: 50%
        :align: center
        
**Enjoy the first of many data cubes!**




