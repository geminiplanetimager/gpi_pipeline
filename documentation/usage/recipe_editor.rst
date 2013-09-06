
.. _recipe_editor:

Recipe Editor
#################


The Recipe Editor is a graphical tool for editing recipe files: changing the 
input files, the 
data processing steps, their order, or the various function parameters. 
It can create, open, and modify reduction recipe files, and save them to a
user-specified directory or add them directly into the reduction queue.
[#footnote1]_


Interface Layout
------------------------

The main sections of the Recipe Editor screen are as follows:

**Selecting FITS Files**: The list at the top left shows the input FITS files for the reduction,
along with buttons for adding, removing, or sorting list items. 

Double clicking on any file name in this list will bring up a gpitv viewer displaying that file.

**Selecting Recipes Templates**: To the right are
two dropdown lists for selecting (a) a reduction type and (b) one of several
predefined reduction templates available for the chosen reduction
type. Selecting one of these templates causes that template to be
loaded into the primitives editing area.

**Primitives and Arguments**: 
The bottom two thirds of the window are devoted to several tables for editing primitives. 
On the left
is a listing of all available primitives for the selected reduction type.
A description of each is displayed below the list when a primitive
is clicked.  To add a primitive to the list, select it and press the 'Add Primitive' button, or as a short cut you can
right click on it.  Similarly, selecting a primitive and pressing the 'Remove Primitive' button will do so. 

The primitives are by default ordered in a
given manner based on the suggested logical sequence of steps, but can be reordered using the 
'Move up' and 'Move down' buttons. 

For primitives with arguments, when that primitive is selected, its argument options will be shown below the active primitive list.
Values for the arguments can be set by double-clicking on a box to
edit it. Don't forget to press enter to validate the input.


Typical Usage
--------------------

The typical usage pattern is to select input files, choose a reduction
template, optionally change configuration parameters from their
default values, and then add the DRF to the reduction queue.

1. To create a Recipe, first load FITS files as desired into the input file
   list using the Add Files or Wildcard buttons.  
2. The Recipe Editor will attempt to guess an appropriate reduction template based on the FITS headers of
   the loaded files (for instance, checking if they are darks or flats or
   science data). If it cannot automatically pick the right type, or if
   you want to do something different, then select a reduction template
   from the drop-down list. 
3. The active primitives list is then populated with
   the set of primitives as specified by the template.    
4. The list of primitives can be edited interactively using the 'Add', 'Remove', and 'Move' buttons
   along the bottom of the screen.
5. Arguments for primitives can be edited as desired. 
6. When the user is satisfied, the primitive can be saved and queued for execution.

Many modules require calibration files to be specified. Typically, recipes
will specify "Automatic" choice of calibration files, which means that the
Calibration Database software should attempt to determine the best 
calibrator from the list of available calibration files. This is the
right choice almost all the time. However, it is possible to manually
select a specific calibration file if desired for some reason. 

Saving and Executing Data Reduction Recipes
-----------------------------------------------

When the recipe is configured as desired, the user can save it to disk for
later use by clicking on the "Save As..." button on the bottom of the GUI or in
the File menu. The Recipe Editor provides an default suggestion of the output
recipe filename, but this can be changed if desired. 


If the user wishes to have the DRP
execute this recipe immediately, then it can be directly added into
the queue by using the 'Queue last saved recipe" button or the
"Save and Queue" button, also on the bottom of the GUI. 



Primitive Classes and the special action "Accumulate Images"
----------------------------------------------------------------

Actions which can take place in the pipeline are divided into two classes::

 * steps which are performed upon each input file individually (for instance
   background subtraction), and 
 * steps which are done to an entire set of files at once (for instance, combination via ADI). 
   
The dividing line between these two levels of action is set by a
special primitive called **Accumulate Images**.  This acts as a marker
for the end of the "for loop" over individual files.  Primitives
listed in a recipe before Accumulate Images will be executed for each
input file in sequence. Then, only after all of those files have been
processed, the primitives listed in the recipe after Accumulate Images
will be executed once only. 

The Accumulate Images primitive has a single option: whether to save
the accumulated files (i.e. the results of the processing for each
input file) as files written to disk (``Method="OnDisk"``) or to just
save all files as variables in memory (``Method="InMemory"``). From
the point of view of the pipeline's execution of subsequent primitives
, these two methods are indistinguishable. The only significant
difference is the obvious one: ``OnDisk`` will produce permanent files
on your hard disk, while ``InMemory`` requires your computer have
sufficient memory to store the entire dataset at once. When dealing
with very large series of files, the ``OnDisk`` option is recommended. 


If you want to create a recipe that only contains Level 2 actions
(i.e. actions on the whole set of input files), you still need to
include an Accumulate Images in the recipe file. The Recipe Editor
will eventually automatically include Accumulate Images where
necessary, but right now you need to add it by hand.

Attempting to execute a recipe which lacks an Accumulate Images call, or
which has Level 2 methods before or Level 1 methods after, has
undefined behavior and will probably not succeed. 



.. rubric:: Footnotes

.. [#footnote1] 
  In normal operations, users should never have to edit recipe XML code directly
  (everything can be done with the GUI), but see the Appendix for XML syntax 
  if desired.


