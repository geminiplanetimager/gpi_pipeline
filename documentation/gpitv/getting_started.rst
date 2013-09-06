Starting GPItv
===============

GPItv can be started from a script or from the IDL command-line prompt.
Start IDL and type ::

        GPItv 

It will display a default 2-d image.

To display an array that is in memory, pass its name to GPItv like this::

        GPItv, array_name [, options]

where array_name  is a two- or three-dimensional array to be displayed.

Similarly, to pass a FITS filename to GPItv, use the command::

        GPItv, "fitsfile_name" [, options]  

where fitsfile_name is a string (enclosed in quotes) containing the name of the
FITS file  (including extension) to be read.   If the filename has a ".gz"
extension, it will be treated as a gzip compressed file and be automatically decompressed before being read. 


For instance, the command ::

        GPItv, 'test.fits'

will display  the file 'test.fits' if  it exists in the current directory. 

GPItv can be started from a script or from the IDL command-line prompt. If
starting from within a script, you may wish to specify the "/block" option to
pause the script while the user works with GPItv, or else use Multi-Session
mode to allow concurrent execution.

Quick Overview 
========================


Figure 1: Overview of the main GPItv window.


In addition to menu functions and mouse modes described below, GPItv has several functions directly available from the main window:

*   A status area which displays the most important identification header information (such as keywords filename, dateobs,...) and current cursor position and related pixel intensity;
*   color map contrast and brightness
*   pan windows to view a zoomed region around the cursor. The mouse can be used to drag the image-view box around, or you can recenter by clicking in the main window.
*   a multi-plane slice slider available for data-cubes 
*   choice of available units (depending on pipeline processing) 
*   box for choice of mouse modes


