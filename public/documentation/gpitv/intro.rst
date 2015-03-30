Summary of Functionality  
############################


GPItv is a display tool that includes features for image analysis and spectral
analysis. 2D image analysis tools are available for image manipulation,
including:

*   Display of 2D/3D images with a variety options for scaling, color map, color stretch, zoom, and rotation. 
*   World coordinate system information (X,Y,lambda) is displayed when appropriate keywords are available in the image header.
*   Viewing and editing image FITS headers
*   Quick photometry and image statistics 
*   Image output in a variety of formats (FITS, PS, JPEG, PNG, & more) 
*   Labeling and overplots to annotate images
*   Display of radial line plots, surface plots, and histograms of data regions 
*   Image blinking
*   Automatic detection of new fits image in chosen directories
*   High-contrast AO contrast assessments 


Spectral analysis tools include:

*   Multi-plane image slider for datacubes 
*   Extraction of 1D spectra from chosen regions
*   Spectral plotting 
*   Display and verification of the wavelength solution
*   Collapse datacube
*   Simple difference Imaging

Polarimetric analysis tools include:

*   Display of polarized datacubes in both Stokes IQUV and perpendicular polarization pair formats
*    Overplotting of polarization vectors, with many configurable options
*   Computation of total intensity, polarized intensity, & polarization fraction from IQUV datacubes. 


One significant enhancement relative to the original ATV program is that
GPItv's internals have been rewritten to allow multiple copies to run
simultaneously. Thus users can view for instance raw frames, reduced datacubes,
and ADI-processed subtracted images all in separate windows simultaneously


.. comment:
    (I would not say anything above developing for gpitv is done "easily"... -MP)
    New features can be added to GPItv easily, including linking to or calling
    existing IDL programs.  For example, you can easily define a keyboard shortcut
    that will pass the current cursor position in data coordinates to an external
    IDL routine.  



