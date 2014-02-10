.. _autoreducer:

Autoreducer 
==============

The Autoreducer GUI provides quick look reductions of GPI data with minimal (or no) human intervention. It is intended primarily for
making real-time reductions at the telescope during observations.  It watches one directory for newly arrived FITS files. 
When a new file is detected, the Autoreducer creates a recipe to reduce that one file based on a pre-identified template recipe, and adds that recipe to the queue. It also can optionally display on screen the new file. 

.. image:: fig_autoreducer.png
        :width: 532 px
        :scale: 75%
        :align: center
 
Basic Operation
-----------------

After opening the Autoreducer window, the user should select the directory to watch for incoming files, using the ``Change directory`` button at the top of the window. Once the desired directory is selected, press the ``Start`` button. The autoreducer will start polling that directory at 1 Hz. 

When new files are detected, the filenames will appear in the 'Detected FITS files' section of the screen.  If the ``View new files in GPItv`` option is enabled (Options menu), the new image will be sent to a GPItv session. 

The automatic reducer will use these templates:

 * "Quicklook Automatic Datacube Extraction" (for spectral mode)
 * "Quicklook Automatic Polarimetry Extraction" (for polarimetry mode)
 * "Quicklook Automatic Undispersed Extraction" (for the no dispersion engineering mode)

If you want to change what actions the Automatic Reducer does for new files, edit your local copies of these templates. 

Re-Reducing Files
------------------

You can re-reduce any given file by selecting it in the Detected FITS files
list and pressing the ``Reprocess Selection`` button. This will treat that file
as if it were newly arrived, and will create and queue a reduction recipe. 


Reduction Options
--------------------
The recipe set that is used by the Automatic Reducer is pretty limited. For more control over reductions, use the :ref:`data_parser` or :ref:`recipe_editor` tools.  

You can choose to, instead of using the default Quicklook recipes mentioned
above, apply some specific other recipe. Just press the ``Specific Recipe``
checkbox and select the desired template from the drop down list. 

The Options Menu allows configuration of several behaviors:

 * **View new files in GPITv** lets the display in GPItv of incoming files be 
   toggled on and off. 
 * **Ignore individual UTR/CDS files** refers to the optional mode of the GPI IFS readout software
   in which all individual reads of an UTR or MCDS sequence are saved to disk
   for postprocessing or analysis. In most cases such files will not be present, but if they are, it's generally 
   convenient to ignore these FITS files for the autoreducer.
 * **IFS Flexure** lets you choose how to correct spectral location calibrations for IFS flexure: Manual
   entry of dx & dy, Automatic correction using a lookup table (which must be in the calibration DB), or None. 
   See the Update Spot Shifts for Flexure primitive for more.


Operation at Gemini
----------------------

If the ``at_gemini`` flag is set to indicate this is the pipeline installation at Gemini South, the autoreducer will configure its
paths and filenames automatically to values appropriate for the Gemini summit network. Also the autoreducer itself will start up
automatically right after the Launcher loads. 

