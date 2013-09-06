Recipes and the Queue
=======================

The pipeline's actions are controlled by scripts known as "Recipes" that
specify input FITS files, various tasks (called "primitives") to run on them,
and options or parameters for those tasks. Any recipe that is written to a 
special queue directory will be detected and run. 


Recipes
-----------

A recipe consists of a list of some number of data processing steps ("primitives"), a list of one or more input files to operate on, and some ancillary information such as what directory the output files should be written to.  
For GPI, recipes are saved as XML files, and while
they may be edited by hand, they are more easily created through the use of the
:ref:`recipe_editor` and :ref:`data_parser` tools. Available primitives are described in detail at :ref:`primitives`.  Some primitives are actions on individual input files one at a time,
for instance dark subtraction or datacube extraction. Other primitives act to
combine multiple files together, for instance ADI combination.

For example, a typical GPI observation will consist of a sequence of
coronagraphic IFS spectroscopic observations of a bright star obtained as the
sky rotates. A Recipe to reduce that observation sequence could consist of the following
steps, each associated with specific piece of code:

* For each image of an observation:

  * Remove detector artifacts
  * Extract Data cube
  * Check data quality
  * Apply flux calibration
  * Apply astrometric calibration

* End of loop 
* Combine all images with an ADI algorithm
* Apply spectral difference (simple SDI speckle suppression algorithm)
* Save result

Predefined lists of steps ("Recipe templates") exist for all standard GPI
observing sequence types. These recipes can be selected and applied to data
using the GUI tools, or automatically executed on data to produce fully
automated quicklook reductions at the telescope. 


Adding Recipes to the Queue
------------------------------

The DRP monitors a certain queue directory for new recipes to run.
Thus, once a recipe has been created, it needs to be placed into the queue in order to be run. 
This can be done manually, as described in the next paragraph,
but for users of the :ref:`recipe_editor` and :ref:`data_parser`
tools there's a button that will automatically queue recipes created with those tools.

The location of
the queue directory is  :ref:`configured during pipeline installation <config-envvars>`.
Any file placed in the queue
with a filename ending in ``".waiting.xml"`` (for instance, something like
``S20130606S0276_001.waiting.xml``) will be interpreted as a pending recipe file ready for
processing. The pipeline will read the file and parse its contents into
instructions and begin executing them.  That file's extension will change to ``.working.xml`` while it is
being processed. If the reduction completes successfully, then the extension will be
changed to ``.done.xml``. If the reduction fails then the extension will be changed
to ``.failed.xml``. The pipeline checks the queue for new recipes once per second by default.
If multiple new recipes files are found at the same time, then the
pipeline will reduce them according to their filenames in alphabetical order. Thus, to queue a recipe
manually, simply copy it into the queue directory with a filename ending in ``".waiting.xml"``. 







