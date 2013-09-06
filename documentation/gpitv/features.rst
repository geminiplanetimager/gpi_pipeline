
Additional Features
======================

Multi-Session Mode 
---------------------------


By default, if you already have a GPItv running and you type
"GPItv, array_name", the display comes up in your previously existing GPItv
window. If you want more than one display window, you can start multiple sessions of GPItv
running simultaneously. 

To start an additional session, use::

        GPItv, fitsfile_name, ses=num

where 'fitsfile_name' is a string containing the name of the FITS file
(including extension and directory if needed) to be read and 'num' is an
integer that defines an integer ID for the gpitv window to be used. 
For example, ::

        GPItv, 'test.fits', ses=0

will display 'test.fits' in session #0. You can launch arbitrarily additional
copies by changing the value of the 'ses' keyword. For instance, ::

        GPItv, 'test2.fits', ses=7

will display 'test2.fits' in an other Gpitv viewer (#7), so you will have two
GPItv viewers opened. Each window will be identified by a unique ID number, shown in
the title bar of the window (and also of any child windows or dialogs that are opened from that particular GPItv). 
You can open as many different sessions as you want. [#footnote1]_

Once a session is running, you can change the image displayed or adjust scaling or other
display parameters with additional calls using the same session number. ::

        GPItv, 'test3.fits', ses=0, /log, min=0, max=1000



Optional Input Keywords
---------------------------------

The command-line options are: 

*   [,/alignp]: preserves the current display center and zoom when reading in a new image. 
*   [,/alignwav]: for data-cubes, keep the same slice number to be displayed. 
*   [,header=header]: use this to enter the FITS header corresponding to an image array.  The FITS header is a string array. 
*   [,min = min_value]: sets the minimum array value to be mapped into the color table.  (can be modified interactively) 
*   [,max=max_value]: sets the maximum array value to be mapped into the color table.  (can be modified interactively) 
*   [,/autoscale]: tells GPItv to set min and max automatically to -2 and +10 sigmas about the image median.  Setting autoscale overrides min and max.  GPItv will autoscale by default, so it's not necessary to include this keyword unless you've turned off default autoscaling. 
*   [,/linear]: maps data values to the color table linearly 
*   [,/log]: maps the log of data values into the color table 
*   [,/histeq]: histogram-equalizes the image into the color table. (good for images with a large dynamic range) 
*   [,/stretch]: preserves the current min/max values when reading in a new image 
*   [,/block]: starts ATV as a blocking widget, which can occasionally be useful

Command Line Interface Advanced Features
----------------------------------------------

To overplot a contour plot on the draw window::

        GPItv->contour, array_name [, options...]

To overplot text on the draw window::

        GPItv->xyouts, x, y, text_string [, options]  

To overplot points or lines on the current plot::

        GPItv->plot, xvector, yvector [, options]

To erases all (or last N) plots and text::

        GPItv->erase [, N]


.. comment the following is I think obsolete 
    When you're debugging a program, and you do not want to use a GPItv
    multi-session mode, it can be useful to block your command line until you tell
    GPItv to quit. You can do this with the /block keyword. If you call GPItv
    without that at first, but then wish to switch to block mode, the command
    GPItv_activate
    will make GPItv active and block your command line.


To quit GPItv from the command line, just type ::

        GPItv->shutdown





The coordinate system
------------------------------

Raw 2D images coming from the GPI IFS will not contain WCS information because
spatial and spectral domains are mixed. However, the GPI data pipeline delivers
datacubes with WCS information. If the image header has a valid world
coordinate system (WCS), then GPItv will display the coordinates of the cursor
position.  By default, it uses the native coordinate system and equinox given
in the image header.  GPItv can also convert the native coordinates into J2000,
B1950, ecliptic, or galactic coordinates.  To change the output to a different
system, go to the ImageInfo menu and select one of the coordinate options.  

If the WCS information describes the 3rd dimension of a datacube in either
spectral or polarimetric format, this information will be displayed as you scan
through the datacube. For this to work, GPItv requires FITS keywords compliant
with the WCS standard as defined in the papers by Griesen & Calabretta, et al. 

Image statistics
------------------------------

The statistics window (Fig.6) shows the min, max, mean, median, number of NaNs,
for a box centered on the cursor position in addition to the image min and max
value. 

To bring up the image statistics window, hit "i", or set the mouse mode to
"Stat" and use left button of the mouse, or select it in the ImageInfo menu.

You can change the box center or the box size by entering new numbers in the
input boxes.  To see a zoomed-in view of the stats region, click on "Show
Region".

Figure 9: Example of basic statistical information given by the Stat/ImExam3d modes, such as mean value, median, std dev, number of Nan.

To display all statistics for a multi-plane datacube (Fig.7), set the mouse
mode to "Stat/ImExam3D" and use right button of the mouse to select a region in
the image (select arbitrary box with two clicks, defining the corners).


Figure 10: Example of image statistics for a multi-plane datacube

Blinking images and making an RGB color image
-----------------------------------------------

GPItv easily allows you to blink images, as follows. Load in the first image,
and get the display exactly how you want it.  Then, go to the Blink menu and
select "Set Blink1".  Then load in the second image and set the mouse mode to
"Blink".  Now, with the cursor in the main draw window, just hold down the
first mouse button to display the first image, and release the button to show
the current image.  

You can save up to 3 blink images and blink them with mouse buttons 1, 2, or 3.
If you have fewer than 3 mouse buttons, you won't be able to use all 3 blink
images.

GPItv can make RGB "true-color" images in a rudimentary way (Fig.8).  To do
this, first set the colormap to grayscale, and don't invert the colormap.  Load
your "R" image and get the color stretch just the way you want it, and then
save it in blink channel 1 with "Set Blink1".  Do the same for your G image in
blink channel 2 and your B image in blink channel 3.  Then, just select
"Blink->MakeRGB" and GPItv will make a truecolor RGB image using the 3 blink
channels. If you like how your RGB image came out, you can save it to a file
using "File->WriteImage" to save it to a jpg, png, or tiff image.  As soon as
you change the display settings, GPItv goes back to its normal display mode
with the last image that was loaded.


Figure 11: Example of a RGB color image using three planes of a datacube.

Automatic Detection of new FITS files
-------------------------------------------

GPItv can watch directories in order to automatically show any new fits files
coming into  those specific chosen directories.

Select "DetectFits" in the File menu, and the 'FitsGet' window will appear
(Fig.9). The left panel allows the user to browse the file system. One click on
a directory will expand it. Double-click on a fits file will display the image
in the GPItv main windows. Double-click on a directory will place it on the
top-right panel which is the list of current directories where new fits files
will be detected.

Add your data repositories in this list. Click the "Search most recent fits files" button to automatically display in the bottom-right panel all fits files contained in the selected directories sorted by creation date from newest to oldest. Every time a new fits file come into these folders, it will appear at the top of this list.

.. _gpitv_wavecal_grid:

Displaying GPI Wavelength Calibration grids
-----------------------------------------------

GPI raw 2D image contains both spatial and spectral information. The wavcal
grid allows the GPI pipeline to extract a 3D datacube from a GPI image. The
wavcal grid contains positions of spectra in the image at a specific
wavelength, tilts of spectra, and coefficients which give the dispersion law of
each spectrum in the image. The wavcal grid is obtained with calibration
narrow-band data, such as Xe arc lamp.    

To select a wavcal grid to overplot, choose the wavcal file with 'Select Wavcal
grid' in the 'Labels' menu, then select 'Plot wavcal grid' in the same menu.

The GPI wavcal grid can be overplotted  on 2D image in order to check out:

* proper calculation of the wavcal grid during engineering measurement
* spatial shifts of micro-lens PSF positions in the image for spectroscopic or
  polarimetric scientific images since the last wavcal solution measurement.

Fig.10 represents a simulated DST/Zemax arc lamp image  with wavcal grid overplotted that shows detected position and tilts of spectra. 

Other functions
--------------------

In addition to the functions described above, GPItv has several useful functions such as 

Measure distance:	
        Measure distance with the mouse 
WriteFits: 
        Write out a new fits image to disk (single-plane or entire image)
WritePS: 
        Write a PostScript file of the current display
WriteImage: 
        Write a JPEG, TIFF, BMP, PICT, or PNG image of the current display
Save to IDL variable: 
        Save current image or cube as an IDL variable
Save/Load Region : 
        Save or load currently displayed regions to a SAOImage/DS9 region file with .reg format                            

Invert the X-axis or Y-axis  of the original image

Rotate image by arbitrary angle

Datacube Default Scaling Mode Droplist
--------------------------------------

When a 3D datacube is opened and you change the plane displayed, the min and max for the display scaling of the new plane can be controlled by the following options:

Constant:		
        Keep Min/Max values the same for each image plane
AutoScale:		
        Set display Min/Max to [-2 sigma, +10 sigma] for the new plane
Min/Max: 		
        Set display Min/Max to Min/Max of the displayed plane


Mouse modes in display window
-----------------------------------

The effect of clicking any of the mouse buttons depends on the 'Mouse Mode' drop-down list setting. 

======================  ====================    =============================   ============================
Mouse Mode              Left Click              Middle Click                    Right Click
======================  ====================    =============================   ============================
Recenter/Color          Recenter                Adjust color stretch            Adjust color stretch
Zoom                    Zoom in                 Recenter                        Zoom out
Blink                   Show blink image #1     Show blink image #2             Show blink image #3
Statistics 2D/3D        Show 2D Statistics      Show 3D Statistics              Show 3D Statistics
Vector                  Plot vector cut         --                              --
                        across the image.                                     
Measure Distance        Measure distance        --                              --
                        between two points
Photometry              Aperture Photometry     Recenter                        Plot Angular Profile
Spectrum Plot           Spectral plot using     --                              Spectral plot of
                        aperture photometry                                     selected pixel
                        around selected 
                        pixel
Draw Region             Draw Region             --                              --
Row/Column Plot         Draw plot of current    --                              Draw plot of current column
                        row in image                                            in image
Gauss Row/Column Plot   Fit Gaussian to         --                              Fit Gaussian to
                        local region of                                         local region of
                        current row in image                                    current column in image
Histogram/Contour Plot  Plot histogram of                                       Draw contour plot of region
                        region around cursor                                    around cursor
Surface Plot            Draw surface plot of
                        region around cursor
======================  ====================    =============================   ============================


Keyboard shortcut commands in display window
-----------------------------------------------
Arrow keys move the cursor around the main image window. 
The numeric keypad (with NUM LOCK on) will also work, and allows motion along diagonals too. 

====    ============
Key     Action   
====    ============
1       Down-Left
2       Down
3       Down-Right
4       Left
6       Right
7       Up-Left
8       Up
9       Up-Right
====    ============
 
Many other shortcuts exist to bring up windows or change settings.  The 'b' and 'n' buttons to move through
datacube slices are particularly useful.


======  =============================================================================================
Key     Action   
======  =============================================================================================
b       Change slice number, previous ("back")
n       Change slice number, next
a       Change image display min/max to Auto-Scale -2/+5 sigma
g       Show region plot
h       Show histogram plot of pixels around current cursor position
c       Show column plot
i       Show image statistics at current position
j       Show 1D Gaussian fit to image rows around current cursor position, +- 10 pixels
k       Show 1D Gaussian fit to image columns around current cursor position, +- 10 pixels
l       Plot pixel value vs wavelength, for 3D images ("l" for "lambda")
m       Change mouse mode (cycles through list of modes, one mode at a time.)
p       Do aperture photometry at current position
q       Quit GPItv
r       Show row plot
s       Show surface plot
t       Show contour plot
y       Recenter plot
z       Show pixel table
E       Erase anything drawn in main window
M       Change image display min/max to image min/max
R       Rotate image by arbitrary angle
\-       Zoom out
\+       Zoom in
======  =============================================================================================

.. comment: This does not appear to be working right now as of 2012-12-03 ?? -MP
   !,@,#   Save current view to blink_image 1,2,3 (note these are Shift-1,2,3 respectively)



.. rubric:: Footnotes

.. [#footnote1] There is no inherent IDL limitation on how many GPItv viewers can
                be displayed, apart from your available computer memory. However, currently the
                max number of sessions is limited to 100, due to the size of a pointer array used internally
                for bookkeeping. It seems unlikely for anyone to want >100 concurrent sessions, but if you do,
                this can be enabled with a trivial code change. 

