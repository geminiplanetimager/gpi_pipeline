Example Usage Cases 
======================



This section is a short tutorial on how to use some of the features of GPItv following a step-by-step process. We will see how to:

*   open an image and change display settings;
*   search a specific keyword in the header of a FITS image; 
*   pick your preferred units;
*   measure contrast curve;
*   detect a companion using Simple Difference Imaging
*   plot the spectrum and brightness of the companion
*   view polarization patterns in a circumstellar disk

Open an image and change display settings:
----------------------------------------------------

We have seen how to open an image with GPItv directly by using an IDL command.
You can also open a new image from the GPItv main window: start 'gpitv' in the
command line and select ReadFits from the File menu, and pick up your fits
file.

Let's see now how to change the display settings. 

By default, the mouse mode is set to "Pos/Color" (look at the Mouse Mode
droplist in the GPItv main window) which means that the left button of the
mouse will center the display on the pixel you left-clicked (corresponding to
gPos' mouse mode). The right button of the mouse change the brightness and the
contrast of the display by dragging the mouse over the main image window with
mouse right button held down ('Color' mode).  Moving the mouse horizontally
changes brightness, and moving vertically changes contrast. 

You can also select the display region by going to the pan window (which
displays a miniature version of the entire image) and dragging the box around
with the mouse.  Or, just click once in the window and the display will center
on the pixel you clicked.  

Typing new values into the "Min" and "Max" boxes at the edge of the colorbar
and pressing Return will change the data range that gets mapped into the color
table.  Click on "FullRange" to set Min and Max to the full data range of the
image.  Click on the "AutoScale" button (default mode) to set the "Min" value
to be the sky median minus 2 times the sky sigma. The "max" value is set to be
either the sky mode plus n times the image standard deviation (n=2 for linear
and n=4 for log scaling), or the maximum pixel value in the image (asinh or
histeq scaling).  The ColorMap menu offers a choice of several color tables. To
invert the color table, just click on the "Invert" button.  When you click the
"Restretch" button, the color table is linearized and the min and max values
are adjusted to preserve the appearance of the image as closely as possible. 

The default image scaling is linear but can be changed to "log", "histeq" or "asinh".

To zoom in or out, while preserving the current central pixel of the display,
click on "ZoomIn" or "ZoomOut".  You can also set the mouse mode to 'Zoom' and
use the mouse right and left buttons. To set the zoom level back to the
default, click on "Zoom1".  To center the image on the display viewport, click
on "Center".


Search a specific keyword in the header of a FITS image: 
--------------------------------------------------------------

A FITS Header Viewer dialog is available, and can be found either on the File
menu or the ImageInfo menu.  The FITS header viewer will appear and all
keywords will be listed with their values and comments. The 'Find keywords'
widget allows the user to search a specific keyword in the list and edit its
value.
  
Pick your preferred units:
-------------------------------
The default unit for a non-processed image is 'Counts'.
If the header of the image contains the exposure time (EXPTIME) and COADDS keywords, units 'Counts' and 'Counts/s' will be available.
If the image has been processed for flux calibration by the GPI data pipeline, the full choice of units will be available ('Counts', 'Counts/s','ph/s/nm/m^2', 'Jy', 'W/m^2/um','ergs/s/cm^2/A','ergs/s/cm^2/Hz'). Pick your preferred units in the 'UNITS' droplist. Units conversion factor used  can be found explicitly on the GEMINI web site (http://www.gemini.edu/sciops/instruments/itc/itcHelp/ITChelpAstroSource.htmlhttp://www.gemini.edu/sciops/instruments/itc/itcHelp/ITChelpAstroSource.html).

Measure contrast curve:
---------------------------


A quick contrast assessment can be obtained for images of occulted star by
using intensities of the satellite images created by the pupil grid. Pixel
intensity of sat image is proportional to the intensity of the star observed
without occultation. First step is to detect properly the sat positions in the
image.  Contrast assessment can be performed on monochromatic images or on
slices of a datacube. Consequently, this function can not be used directly for
GPI raw images. 

Fig. 2 shows the window that give access to parameters and results of contrast assessment.

The GPItv contrast curve window contains a control panel which allows the user to change the parameters of the satellite detection:

* The grid factor converts integrated fluxes of sat images into fluxes of the star observed without occultation.
* Initial positions of box windows for sat detection should be changed in case of satellite misdetection.

The method used to detect the sat image is based on a maximum intensity
detection followed by a Gaussian fit. Firstly, position of the maximal pixel
intensity is detected and a 2D gaussian fit is performed in order to calculate
the position of the sat in the image. After, pixel intensities are integrated
over a box centered on the sat images that gives two total intensities for the
two sat. The mean value is calculated and this value is multiplied by the grid
factor to give the unocculted star flux assessment. Note that if fluxes
relative difference exceeds 25%, the program will avert that a possible
misdetection has occurred. The contrast is given by dividing the main image by
the mean flux of the sat images. The center of the image is masked (0.12
arcsec) in order to take into account the focal plane mask effect. The contrast
profile as a function of the angular separation is then calculated and a
1dimensional plot is displayed (median values over annuli centered on the star
position are calculated).

* the size of the box for maximal pixel intensity detection can be modified.
* the size of the box for 2dimensional Gaussian fit can be modified.

Detect a companion using Simple Difference Imaging:
----------------------------------------------------------


It is also possible to calculate a simple difference imaging on an extracted datacube in order to detect faint companions. 

Choose 'Collapse by SDI' in the multi-wavelength panel (where the default
choice of the droplist is 'Show cube slices'). It will open a window which
allows the user to control the SDI parameters. Some predefined spectral bands
('Methane') are defined but wavelength ranges can be user-defined by selecting
'User-defined' in the Band droplist.

Fig.3 shows the SDI window that allow you to modify calculation parameters.a

Parameters Wav1 and Wav2 defined respectively the min and the max wavelengths
of the first spectral band to consider (in microm). Wav3 and Wav4 defined
similarly the second spectral band. If the bandwidth is large enough to contain
several slices of the datacube, they will be averaged in order to have 2
frames, Im1 and Im2, for the 2 spectral bands.

The first frame obtained (Im1) is spatially rescaled in order to have speckle
patterns with the same size for the 2 frames. We assume that the frames are
aligned and registered.

The scaling factor k (which is user-defined) will affect the first frame (Im1)
as the final result is given  by Im2-k*rescaled(Im1).


	Figure 3 : Simple Difference Imaging for a data-cube.

Plot the spectrum and brightness of the companion
---------------------------------------------------------

When a datacube has been chosen to be displayed, GPItv shows only one slice of
the datacube that corresponds to a quasi-monochromatic image. To change the
slice to display, GPItv has several multi-wavelength controls (like multi-plane
slider). But it can also be useful to display intensities as a function of the
wavelength for a given angular position. 

The mouse-mode droplist gives this possibility by selecting 'Spaxel' in this
droplist. When left-click on a specific position in the image, a new window
will appear to display the spectrum. Fig.4 represents the window that will be
opened to plot spectrum vs wavelength.

It gives the current cursor position chosen in the image and the right-top
panel displayed the sub-region chosen in the image. For each wavelength (or
slice of the cube), intensities are integrated over a circular aperture. The
radius of this aperture can be modified by the user and a green circle will
display the aperture chosen. Three methods can be chosen to integrate
intensities : 'Total' which is a simple sum excluding Nan, or 'Median' or
'Mean'.

Aperture photometry (using IDLastro daophot routine) can be brought up by
selecting AngProf/Apphot in the 'Mouse Mode' droplist, or directly by hitting
"p" when the cursor is on the object you want to measure. When right-clicking
on a specific region in the image, a new window will appear and it will find
the center of the object selected. Fig.5 represents the photometry window with
results and modifiable parameters. It will display the zoomed region around the
photometry point, with circles showing the photometric aperture and sky radii.
This routine calculates the median sky value in the sky annulus, subtract this
value from each pixel in the sub-image and calculate the total flux in the
aperture. The window displays the cursor position, and the routine computes
object centroid, sky level, and number of counts in the aperture.  By changing
the text in the input boxes, you can modify the centering box size, the
photometric aperture radius, and the inner and outer sky radii.  Be sure to hit
"Return" after changing one of these numbers, otherwise they won't be input
into the photometry routines.  

The FWHM is measured directly from the radial profile. Its calculation is not based on a fit to the profile but on the radius at which the count level drops to half of its peak value. Flux and FWHM of the object , sky level,  and the centroid x and y of the object selected are displayed.

Working with Polarimetric Images 
--------------------------------------------


GPI polarization data comes in two datacube file formats: 

*   **perpendicular polarization** files, which have 2 slices each of which
    corresponds to two perpendicular linear polarizations as split by the
    Wollaston prism. 

*   **Stokes cubes**, which have 3-4 slices corresponding to the Stokes vectors. 

GPItv can display and interpret both of these kinds of files, using FITS header
keywords to determine the correct display mode. For either mode, the
"Wavelength" display field in GPItv is replaced with a "Polariz.=" field, which
shows the type of polarization. 

For perpendicular polarization files, the two orthogonal polarizations are
labeled as XX and YY (following a notation that will be familiar to radio
astronomers...).  The actual directions on the sky for the electric field for
these polarizations will depend on both the sky position angle rotation
relative to GPI and the rotation setting of the waveplate. This will vary for
each file in a sequence, but they're always just displayed as just XX or YY.

Figure 6: GPItv showing a perpendicular polarization file. Notice the slider
shows that the YY polarization is shown.

For perpendicular polarization files, the Collapse menu contains an option to
difference the two frames. This is a very simple way of checking for polarized
structure in the image at a basic level. 

For Stokes cube files, the Collapse drop-down list instead contains options to
either show the individual slices (I, Q, U) or to display the linear polarized
intensity [ sqrt(Q^2+U^2) ] or the polarization fraction [ sqrt(Q^2+U^2) / I ]. 

For Stokes cubes, you can overplot polarization position vectors by selecting
Polarization from the Labels menu. This brings up a control dialog for
configuring the vector overplot. You can specify maximum or minimum threshholds
for the vectors to display, and set a magnification factor to make the vectors
all longer or shorter.   


Figure 7: GPItv showing a Stokes cube polarization file. This time the Stokes U
parameter is displayed. Note that the image contains both positive and negative
counts now.

 
Figure 8: Polarization vector dialog and an example of some vectors.

