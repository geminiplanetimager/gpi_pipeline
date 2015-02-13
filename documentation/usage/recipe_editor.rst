
.. _recipe_editor:

Recipe Editor
#################


The Recipe Editor is a graphical tool for editing recipe files: changing the 
input files, the 
data processing steps, their order, or the various function parameters. 
It can create, open, and modify reduction recipe files, and save them to a
user-specified directory or add them directly into the reduction queue.
[#footnote1]_

.. image:: fig_recipeeditor.png
        :width: 2268 px
        :scale: 25%
        :align: center
 



Interface Layout
------------------------

The main sections of the Recipe Editor screen are as follows:

.. image:: fig_recipeeditor_annotated.png
        :width: 2268 px
        :scale: 25%
        :align: center
 


**Input FITS Files**: The list at the top left shows the input FITS files for the recipe,
along with buttons for adding or removing them.  
Double clicking on any file name in this list will bring up a gpitv viewer displaying that file.

**Selecting Recipes Templates**: To the right is a dropdown list for selecting the reduction type
and a button that allows you to load a predefined recipe template.  Clicking this button will produce
a menu of template options as in the figure below:

.. image:: fig_recipeeditor_templateselect.png
        :width: 1309 px
        :scale: 40%
        :align: center

Selecting one of these templates causes that template to be
loaded into the primitives editing area.  Changing the reduction category changes the templates and primitives that 
are available for selection.

The name of the current recipe is shown in a textbox below the category dropdown and template select button.  This field is editable and its contents are used when saving a recipe.  If you create a custom recipe, it is a good idea to update the name to reflect the differences from the template you started from.

**Primitives and Arguments**: 
The bottom two thirds of the window are devoted to several tables for editing the contents of the current recipe.

At the center right is a table listing the primitives in the current recipe. 
The primitives are by default ordered based on a recommended logical sequence of steps, but can be reordered using the 
'Move up' and 'Move down' buttons. 

On the left is a list of all available primitives for the selected reduction
type.  A description of each is displayed below the list when a primitive is
clicked.  To add a primitive to the current recipe, select it and press the 'Add
Primitive' button, or as a short cut you can right click on it.  Similarly,
selecting a primitive in the recipe and pressing the 'Remove Primitive' button will do so. 

For primitives with adjustable parameters, when that primitive is selected in the Primitives table, its parameters will be shown in the lower right table.
Values for the arguments can be set by double-clicking on a value to
edit it. The Range column displays the range of allowable values. After entering a new value, don't forget to press enter to validate and apply the input.

.. caution::

    Note that the Recipe Editor has some rudimentary protection against making nonsensical recipes - for instance the
    bounds checking for argument ranges. But it doesn't prohibit you from re-arranging primitives into orders that
    don't make sense, trying to mix together incompatible primitives, or trying to apply primitives to inappropriate input files. 
    Such recipes will generally just fail and display error messages when you try to run them. 


Typical Usage
--------------------

The typical usage pattern is to select input files, choose a reduction
template, optionally change configuration parameters from their
default values, and then add the DRF to the reduction queue.

1. To create a Recipe, first load FITS files into the input file
   list using the Add Files or Wildcard buttons.  
2. The Recipe Editor will attempt to guess an appropriate reduction template based on the FITS headers of
   the loaded files (for instance, checking if they are darks or flats or
   science data). If it cannot automatically pick the right type, or if
   you want to do something different, then select the desired reduction template
   from the drop-down list. 
3. The current primitives list is then populated with
   the set of primitives specified by the template.    
4. The list of primitives can be edited interactively using the 'Add', 'Remove', and 'Move' buttons
   along the bottom of the screen.
5. Arguments for primitives can be edited as desired. 
6. When satisfied, the recipe can be saved and queued for execution.

**Working with Calibration Files**: Many primitives require calibration files
to be specified. Typically, recipes will specify "Automatic" choice of
calibration files, which means that the Calibration Database should
automatically determine the best choice from the list of available calibration
files. This is usually the right choice. However, if you do wish to adjust the
Calibration File argument for a given primitive, select that primitive then
press the 'Select Calibration File' button.  In the resulting dialog box  you
can manually choose a file from the Calibration Database. If you change your
mind, that same button will let you switch back to Automatic calibration file
selection.

Saving and Executing Data Reduction Recipes
-----------------------------------------------

Once the recipe is configured as desired, the user can save it to disk for
later use by clicking on the "Save As..." button on the bottom of the GUI or in
the File menu. The Recipe Editor provides a default suggestion for the output
recipe filename, but this can be changed if desired. 

If the user wishes to have the DRP
execute this recipe immediately, then it can be directly added into
the queue by using the 'Queue last saved recipe" button or the
"Save and Queue" button, also on the bottom of the GUI. 



.. rubric:: Footnotes

.. [#footnote1] 
  In normal operations, users should never have to edit recipe XML code directly
  (everything can be done with the GUI), but see the Appendix for XML syntax 
  if desired.


