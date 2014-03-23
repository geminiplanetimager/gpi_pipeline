Recipes and the Queue
=======================

The pipeline's actions are controlled by "Recipes" that
specify input FITS files, various tasks (called "primitives") to run on them,
and options or parameters for those tasks. Any recipe that is written to the
queue directory will be detected and run. 


.. _recipes:

Recipes
-----------

A recipe consists of a list of some number of data processing steps ("primitives"), a list of one or more input files to operate on, and some ancillary information such as what directory the output files should be written to.  
For GPI, recipes are saved as XML files, and while
they may be edited by hand, they are more easily created through the use of the
:ref:`recipe_editor` and :ref:`data_parser` tools. Available primitives are described in detail at :ref:`primitives`.  Some primitives are actions on individual input files one at a time,
for instance :ref:`Subtract Dark Background <SubtractDarkBackground>` or :ref:`Assemble Datacube <AssembleDatacube>`. Other primitives act to
combine multiple files together, for instance :ref:`ADI with LOCI <ADIwithLOCI>`.

For example, a typical GPI observation will consist of a sequence of
coronagraphic IFS spectroscopic observations of a bright star obtained as the
sky rotates. A Recipe to reduce that observation sequence could consist of the following
steps, each associated with specific primitives:

* For each exposure of an observation sequence:

  * Remove detector artifacts. 

   * :ref:`Subtract Dark Background <SubtractDarkBackground>`
   * :ref:`Destripe science frame <Destripescienceframe>`
   * :ref:`Interpolate bad pixels in 2D frame <Interpolatebadpixelsin2Dframe>`

  * Assemble a 3D spectral datacube.

   * :ref:`Load Wavelength Calibration <LoadWavelengthCalibration>`
   * :ref:`Update Spot Shifts for Flexure <UpdateSpotShiftsforFlexure>`
   * :ref:`Assemble Spectral Datacube <AssembleSpectralDatacube>`
   * :ref:`Interpolate Wavelength Axis <InterpolateWavelengthAxis>`

  * Apply astrometric calibration.

   * :ref:`Update World Coordinates <UpdateWorldCoordinates>`

  * Derive calibrations based on satellite spots

   * :ref:`Measure satellite spot locations <Measuresatellitespotlocations>`
   * :ref:`Measure satellite spot peak fluxes <Measuresatellitespotpeakfluxes>`
   * :ref:`Calibrate Photometric Flux <CalibratePhotometricFlux>`

  * End of for loop over each exposure  (:ref:`Accumulate Images <AccumulateImages>`)

* For all the images at once: 

  * Perform PSF subtraction of all images with an ADI algorithm (:ref:`ADI with LOCI <ADIwithLOCI>`)
  * Apply spectral difference (:ref:`Simple SSDI of median ADI residual <SimpleSSDIofmedianADIresidual>`) 
  * Combine the results from ADI (:ref:`Median ADI data-cubes <MedianADIdata-cubes>`
  * Save the result

Predefined lists of steps (:ref:`templates`) exist for standard GPI
reduction tasks. These recipes can be selected and applied to data
using the GUI tools. The quicklook recipes automatically executed at the telescope
are included as additional templates so that users may repeat their own quicklook reductions if desired.

.. _queue:

Adding Recipes to the Queue
------------------------------

The DRP monitors a certain queue directory  for new recipes to run.
The location of
the queue is :ref:`configured during pipeline installation <config-envvars>` with the environment variable ``$GPI_DRP_QUEUE_DIR``.

Once a recipe has been created, it needs to be placed into the queue to be processed. 
This can be done manually, 
but for users of the :ref:`recipe_editor` and :ref:`data_parser`
tools, there are buttons to directly queue recipes from those tools.

**How the Queue works:** For cross-platform portability the queue is implemented with a very simple
directory plus filename mechanism.  Any file placed in the queue
with a filename ending in ``".waiting.xml"`` (for instance, something like
``S20130606S0276_001.waiting.xml``) will be interpreted as a pending recipe file ready for
processing. The pipeline will read the file, parse its contents into
instructions, and begin executing them.  That file's extension will change to ``.working.xml`` while it is
being processed. If the reduction completes successfully, then the extension will be
changed to ``.done.xml``. If the reduction fails then the extension will be changed
to ``.failed.xml``. The pipeline checks the queue for new recipes once per second by default.
If multiple new recipes files are found at the same time, then the
pipeline will reduce them according to their filenames in alphabetical order. Thus, to queue a recipe
manually, simply copy it into the queue directory with a filename ending in ``".waiting.xml"``. 




Primitive classes and the special action "Accumulate Images"
----------------------------------------------------------------

Primitives in the pipeline are loosely divided into two levels:

 * "Level 1" steps that should be performed upon each input file individually (for instance
   background subtraction), and 
 * "Level 2" steps that are done to an entire set of files at once (for instance, combination via ADI). 
   
The dividing line between these two levels of action is set by a
special primitive called :ref:`Accumulate Images <AccumulateImages>`.  
This acts as a marker
for the end of the "for loop" over individual files.  Primitives
in a recipe before Accumulate Images will be executed for each
input file in sequence. Then, only after all of those files have been
processed, the primitives listed in the recipe after Accumulate Images
will be executed once only. 

The Accumulate Images primitive has a single option: whether to save the
accumulated files (i.e. the results of the processing for each input file) as
files written to disk (``Method="OnDisk"``) or to just save all files as
variables in memory (``Method="InMemory"``). From the point of view of the
pipeline's execution of subsequent primitives, these two methods are
indistinguishable. The only significant difference is the obvious one:
``OnDisk`` will produce permanent files on your hard disk, while ``InMemory``
requires your computer have sufficient memory to store the entire dataset at
once. When dealing with very large series of files, the ``OnDisk`` option is
recommended. 

If you want to create a recipe that only contains actions on
the whole set of input files, you still need to
include an Accumulate Images in the recipe file, for instance as its first step. 
It's of course possible come up with nonsensical combinations of primitives, 
for instance trying to use an ADI primitive before accumulating multiple input images. 
Such recipes will almost certainly fail. 



