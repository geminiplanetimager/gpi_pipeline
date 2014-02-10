
Pipeline Conceptual Overview
==================================

The GPI IFS data reduction pipeline meets the following top level requirements:

1. It contains the necessary tools to convert raw data into fully calibrated spectroscopic and polarimetric data sets, ready for scientific analysis. 
2. It includes speckle suppression algorithms to improve the contrast performance of the reduced data. 
3. It contains an interactive data viewer, :ref:`GPItv <gpitv>`, specifically adapted for GPI data quicklook and post-observing analysis.
4. It is designed to be modular and adaptable.
5. To a certain extent, it can run as an automated process with minimal human interaction.


The data pipeline comprises several main components, all written in IDL: 

* the **Data Reduction Pipeline** itself (DRP), 
* **Graphical user interfaces** for controlling pipeline operation, 
  including the :ref:`recipe_editor` and :ref:`data_parser`, a :ref:`status_console`, etc. 
* A :ref:`Calibration Database <calibdb>` that stores reduced calibration files of various types,
  and automatically provides appropriate files as needed during data processing.
* and a **customized data viewer** & analysis tool called :ref:`GPItv <gpitv>`.
  
Reduction tasks are defined by :ref:`recipes`, which list both the specific reduction steps (:ref:`primitives <primitives>`)
and the data files to apply those steps to. 
When running, the DRP constantly monitors a :ref:`queue <queue>` for new recipes to reduce. During observations, an
:ref:`autoreducer` generates quicklook reduction recipes on the fly as data is taken.
After observations, the :ref:`data_parser` and :ref:`recipe_editor` can be used to create and adjust additional recipes.
Reduced calibration files are stored in a special
:ref:`Calibrations Database <calibdb>` allowing appropriate calibrations to be retrieved
automatically at each step of data reducion. As the pipeline processes data,
it can also display plots or figures on screen, or send data to the GPItv
display tool for interactive exploration of images and
spectra. A :ref:`status_console` provides a status display
of the data reduction process, and keeps a :ref:`log <logging>` of all messages generated during
reduction. 

The most complex step in the data reduction is the conversion from 2D raw IFS
frames to 3D datacubes. Because the light from each lenslet in the IFS is
dispersed across many detector pixels, the process of uniquely assigning flux
from detector pixels back to GPI's field of view is complex. This is called
'Data-cube Assembly'. The overall process is analogous for both
spectral and polarimetry modes, though algorithmic details differ. 

For each
mode (prism+filter choice), a map of the reimaged lenslet array geometry 
must be made based on observations of calibration lamps
(e.g. the locations and wavelength solutions of the ~37000 microspectra). This calibration data 
is produced from arc lamps for use in the extraction process. Obtaining the 
necessary lamp data is expected to be part of Gemini's facility calibrations rather than
requiring calibration by individual users. Photometric, spectral, and
polarimetric standards must be observed at night in the usual manner. The GPI DRP
is designed to reduce all of this calibration data, and to
reduce scientific data to the level where an astronomer can begin custom
analyses.  

The GPI DRP includes primitives for PSF subtraction using Spectral and Angular Differential
Imaging, implemented both using least-squares (LOCI) and principal component analysis (PCA/KLIP) algorithms.
But it is expected that many uses will wish to use PSF subtraction methods of their own devising on the 
output data cubes from the pipeline. Likewise the GPI DRP includes primitives for 
polarimetric differential imaging.


