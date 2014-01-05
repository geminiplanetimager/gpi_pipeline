GPItv Development
#########################

Overview
====================

GPItv is derived from `atv by Aaron Barth et al.
<http://www.physics.uci.edu/~barth/atv/>`_, but with very, very substantial
modifications. In particular, it was re-cast into an object-oriented IDL
program by Marshall Perrin, and all use of common blocks eliminated. This lets
one open many independent copies of GPItv at once, something that is not
possible with ATV. 

.. warning::
    GPItv is a very large, very complex program with lots of internal dependencies and complex data structures, 
    extensive use of IDL's object orientation, pointers, and widget programming techniques. If you're not already a 
    black-belt IDL guru, you will be soon!
    
Design Principles and Dependencies
====================================
While GPItv is intended as a quick-look tool, it also contains a large amount of advanced functionality geared specifically towards GPI data.  In cases where the functionality mirrors that of the GPI data pipeline, the pipeline backend functions and configuration files are used in order to ensure consistent results.  This means that the GPItv installation is dependent on a working pipeline installation.  Both GPItv and the pipeline use a wide variety of routines from the IDL Astronomy User's Library (http://idlastro.gsfc.nasa.gov/) and the Coyote Library (http://www.idlcoyote.com/documents/programs.php).


Value Storage
===================

The vast majority of internal information in GPItv is stored in a top level state structure, which is referenced via a pointer ``state`` in the GPItv object instance.  Internal GPItv programs can access this structure as::

        *self.state

The state structure is initialized in ``GPItv::initcommon`` and contains all of the default (and user set) values used by GPItv's subfunctions along with pointers to subwindows and child GUIs.

To aid in debugging, it is possible to dump the top level state structure by hitting ctrl+d with the main GPItv window in focus.  The state structure is written to the MAIN level variable ``state``, overwriting any previous data stored there.  This is accomplished by issuing the command::

        (scope_varfetch('state',  level=1, /enter)) = *self.state
    
Two additional top level structures, ``images`` and ``satspots`` are used for image-specific data storage and are described below.

.. _image-storage:

Image Storage
========================
All image data is stored in the top level structure ``images``, with pointers to various data values.  These are:

``images.main_image``
        The image currently being displayed in its native units (unscaled)
``images.main_image_stack``
        The image cube (equal to main_image for 2D images)
``images.main_image_backup``
        The original image cube
``images.names_stack``
        Image names (if available)
``images.display_image``
        Scaled and stretched version of image currently being displayed
``images.scaled_image``
        Bytscaled version of image
``images.blink_image1-3``
        Blink images (also used as RGB channels) 
``images.unblink_image``
        Image being displayed before blink mode is entered
``images.bmask_image_stack``
        Largely unused (maybe should be deprecated?)
``images.bmask_image``
        bit mask image
``images.pan_image``
        Miniature version of full image used for panning
``images.klip_image``
        Backup of KLIP cube (cleared when KLIP settings are changed)

The main image backup is set only when a new image is loaded (in
``GPItv::setup_new_image``).  It should not be overwritten anywhere else in the
code.  The main image and main image stack, however, are changed whenever
required, such as when units are changed, or a collapse mode is applied.

All pointers in this structure must be freed on cleanup.

.. note::
    In order to expand the ``images`` structure changes must be made in 3 locations:  The new field must be added to the ``images`` structure in ``GPItv__define``, the pointer must be initialized in ``GPItv::initcommon`` and the pointer must be freed in ``GPItv::cleanup``.  Most data in this structure should also be cleared/updated when new files are loaded in ``GPItv::setup_new_image``.


Satellite Spots and Contour Profiles
=======================================

Satellite spots and derived quantities (such as contrast profiles) are stored in the top level structure ``satspots``, with pointers to data values or pointer arrays.  These are:

``satspots.cens``
        2x4xZ array of sat spot centers (subpixel coordinates)
``satspots.warns``
        Zx1 array of warnings (0: no warning; 1: fluxes vary by more than 25%; -1: no spots found)
``satspots.good``
        Indices of slices where all spots were found
``satspots.satflux``
        4xZ array of sat spot fluxes
``satspots.contrprof``
        Contour profile (will be Z x 3 pointer array with second dimension being stdev,median,mean)
``satspots.asec``
        Zx1 pointer array of angular separation values associated with each contrast profile (arcsec)

where Z is the number of cube slices (1 for 2D images).  Satellite spots should
only need to be detected once per image (unless the original detection was
bad).   Therefore they are kept in memory and reused by a variety of
subfunctions.  To check whether they exist for the current image, you can
compare their size to the expected one::

        n_elements(*self.satspots.cens) ne 8L * (*self.state).image_size[2]

To update the locations, use ``GPItv::update_sat_spots``.  This takes an optional
keyword ``locs0`` of initial guesses as to the locations in the currently displayed
slice (otherwise, these are automatically detected).  Satellite spot locations
are always determined by using the main image backup, so the values will point
to the pixel locations in the original, uncollapsed image cube.

Contrast profiles are similarly calculated on the fly and stored in memory
against future use.  This is done in ``GPItv::contrprof_refresh``. Note that
contrast profiles are only stored for uncollapsed cubes (i.e., when operating
either in "Show Cube Slices" or "Align Speckle" modes).  If in any other
collapse mode, contrast profiles are generated on the fly and not stored.

All pointers in the satspots structure must be freed on cleanup.  Furthermore, satpot locations and contour profile pointers are freed and re-initialized upon loading a new image (in load_new_image) so that old values are not accidentally used.

Expanding the satspots structure requires edits in multiple locations.  See the note for Image Storage, above.

.. _collapse-modes:

Collapse Modes
===================
The current set of available collapse modes is stored in the value of the collapse button and can be retrieved via::

        widget_control, (*self.state).collapse_button, get_value=modelist

The index of the current collapse mode is stored in state variable ``collapse``.
Note that the zeroeth mode always corresponds to the original image (cube).
For spectral cubes, all collapse modes produce 2D images with three exceptions: Speckle Alignment, KLIP and High-Pass Filtering.
These are tracked with three boolean state variables: ``specalign_mode``, ``klip_mode``, and ``high_pass_mode`` respectively.  
Thus, the only time you are operating on a 3D cube is when state variable
``collapse`` equals 0 or ``specalign_mode``, ``klip_mode`` or ``high_pass_mode`` do not equal zero. 
To check for an uncollapsed cube, use::

        ((*self.state).collapse eq 0) || ((*self.state).specalign_mode eq 1) || ((*self.state).klip_mode eq 1) || ((*self.state).high_pass_mode eq 1) 
 

To check for a collapsed cube, use::

        ((*self.state).collapse ne 0) && ((*self.state).specalign_mode ne 1)  && ((*self.state).klip_mode ne 1) && ((*self.state).hgih_pass_mode ne 1)



All of the collapse modes overwrite the main image var with a collapsed image,
except for Speckle Alignment and KLIP, which replace both ``main_image`` and ``main_image_stack``.
To revert back to the original image, the main image stack is restored from the main image backup.  When a new image
is loaded, the collapse mode is automatically set to 0 (Show Cube Slices for spectral cubes).

Scaling
==========

GPItv currently offers five scaling modes: linear, logarithmic, histogram
equalized, square root and asinh.  These (and any new ones to be added) are
stored in the state variable ``scalings`` (string array).  The current scaling is
stored in the state variable ``scaling`` (string - note that this used to be an
integer indexing the above array, but was changed for easier parseability).
The scalings may be set via the Scale menu, or by passing the corresponding
keyword to a call to GPItv.

The current scaling is updated with a call to ``GPItv::setscaling`` which updates
the state variable and checks (and unchecks) the appropriate menu items.  It
then calls ``GPItv::displayall``, which is simply a wrapper calling
``GPItv::scaleimage``, ``GPItv::makepan``, ``GPItv::settitle``, and ``GPItv::refresh``.

The only other routine affected by the scaling mode is ``GPItv::restretch``.
This one currently has dummy code (cloned from the linear case) for a few of
the modes and so still needs more work.

Message Output
=================

All user messaging should be done via ``GPItv::message`` (i.e., ``self->message``
internally).  This function takes in a message string and two optional
parameters: ``msgtype`` and ``window``.  ``msgtype`` can be "information", "warning", or
"error" and defaults to "information" if not set.  If ``/window`` is set, the
message will appear in a dialog box, otherwise it will be printed to the
command line.  Use of this function allows user control over the number of
messages printed by giving the option of suppressing information and/or warning
messages.  Errors may not be suppressed. 


The call sequence for loading new images in GPItv
======================================================

Loading new images in GPItv is regrettably complicated. The call stack is
enormous and, at times, convoluted. Here are some notes on what gets called inside
each function to help interested readers keep the sequence of events straight. 

In an attempt to ensure a single path for new data through the code, we use a top-level management function: ``GPItv::open``. This takes in two inputs and passes through all keywords.  If the first input is a string, it is assumed to be a filename and passed to ``GPItv::readfits``, which in turn calls one of ``GPItv::plainfits_read, fitsext_read_GPI, fitsext_read_ask_extension, wpfc2_read, twomass_read`` and then calls ``GPItv::setup_new_image``.  ``GPItv::readfits`` handles input keyword ``imname``, appending the filename read in to any user input, and passes through all other keywords.

If the first input to ``GPItv::open`` is not a string, it is assumed to be a data array, is assigned to the ``main_image`` variable in the ``images`` structure (see :ref:`image-storage`) and then calls ``GPItv::setup_new_image``.  The second input (if it exists) is assumed to be the header (string) array or an array of pointers to the primary and extension headers, and is assigned to keywords ``header`` and ``extensionhead``, respectively.  

.. note::
    For historical reasons, the primary header is passed to GPItv as an input, but processed internally as a keyword (along with a separate keyword for the science extension header).  Because all keywords are passed through the main calling level and the ``open`` function, there is a possibility of collision between the header input and keyword.  To prevent this from happening, any header and extensionheader keyword entries are stripped from the input in the case when a filename is passed in, and the header input is used to overwrite any keywords in the case when data is passed in.
    
Finally, ``GPItv::switchextension``, which can load different extensions when the file GPItv is currently displaying was read from disk, also calls ``GPItv::setup_new_image``.

``GPItv::setup_new_image`` is responsible for clearing any information related to any previously loaded image and populating as many internal values and storage locations as possible from the new inputs.  It defaults to the 0 index collapse mode (see :ref:`collapse-modes`) and clears any data related to KLIP processing, satellite spots and contour profiles.  It stores the input data to the main image array and stack and creates the backup in the main image backup (see :ref:`image-storage`).  It assigns any header information to the proper header pointers via ``GPItv::setheader`` and then calls ``GPItv::setheadinfo`` which parses the headers and extracts details about the data.  Finally, it calls: ::

    GPItv::recenter
    GPItv::settitle
    GPItv::set_minmax
    GPItv::collapsecube
    GPItv::setcubeslicelabel
    GPItv::displayall
    GPItv::autozoom (if autozoom is set)
    GPItv::update_child_windows
    
which center the image, set the main window title, update the displayed min/max values, set the collapse mode, set the label of the current slice (if the image is a cube), update all main window displays, and update any subwindow displays (see :ref:`gpitv-subwindows`).

``GPItv::setup_new_image`` explicitly handles the following keywords: 

* ``imname`` Image name
* ``dispwavecalgrid`` Wavelength solution to overlay on image
* ``min = minimum, max = maximum`` Image scaling values (overrides autoscale)
* ``\linear, \log, \sqrt, \histeq, \asinh`` Stretch to use (overrides default stretch).

``GPItv::setheader`` handles the ``extensionhead`` keyword.  All other keyword inputs are ignored (but will not produce errors).

.. _gpitv-subwindows:

GPItv Subwindows and Event Handlers
=====================================

Because of GPItv's complexity and large number of sub-programs and child windows, it is useful to utilize generic event handling as much as possible (thereby avoiding needless code replication and confusion).  This is achieved with a set of programs called ``GPItvo_generic_event_handler``, ``GPItvo_subwindow_event_handler``, and ``GPItvo_menu_event``.

The generic and subwindow even handlers are essentially identical, the only difference being the inclusion of a check for object validity which avoids errors when events come from objects as they are being destroyed.  Otherwise, both handlers look up the information structure associated with the object which spawned the event, and then execute the handling method specified in this structure::
        
          WIDGET_CONTROL, ev.top, get_Uvalue = myInfo 
          CALL_METHOD, myInfo.method, myInfo.object, ev 

The generic event handler is used for subfunctions whose events are generated in the main GUI, while the subwindow event handler is used for all child windows.  The menu event handler is used only for the main GUI top menu, and thus explicitly calls subfunction ``GPItv::topmenu_event``.

When defining a new GPItv subwindow, the procedure is as follows:

#.  Create the widget base and assign to and identification variable in the ``state`` structure (in this example we will call our subwindow 'new')::
        
        (*self.state).new_base_id = widget_base(...)

#.  Populate the base with content
#.  Generate the window and register with the xmanager::
    
        widget_control, (*self.state).new_base_id, /realize
        xmanager, self.xname+'_new', (*self.state).new_base_id, /no_block

#.  Assign the event function to the information structure for the new object and set the event handler::
    
        widget_control, (*self.state).new_base_id, set_uvalue={object: self, method: 'new_event'}
        widget_control, (*self.state).new_base_id,event_pro = 'GPItvo_subwindow_event_handler'

#.  Write the event handling code for your new subwindow in ``GPItv::new_event``.


This framework minimizes repeated code while retaining complete flexibility in event handling for all child windows.  It also makes it trivial to check whether a subwindow already exists, thereby minimizing redrawing time, by using::

        xregistered(self.xname+'_new', /noshow)

.. note::
    More complex subwindows, such as the contrast profile display, will often use multiple separate subfunctions, with a simple event handler that then calls specialized code, as needed.


This approach is based on design principles described by Michael Galloy at http://michaelgalloy.com/2006/06/14/object-widgets.html


