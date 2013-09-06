
Pipeline Conceptual Overview
==================================

The GPI IFS data reduction pipeline has the following top level requirements:

1. It contains all necessary tools to convert raw data into fully calibrated spectroscopic and polarimetric data sets, ready for scientific analysis. 
2. It is designed to be modular and adaptable.
3. It contains an interactive data viewer, :ref:`GPItv <gpitv>`, specifically adapted for GPI data quicklook and post-observing analysis.
4. It includes speckle suppression algorithms to improve the contrast performance of the reduced data. 
5. To a certain extent, it can run as an automated process with minimal human interaction.


The data pipeline comprises several main components, all written in IDL: 

* the **Data Reduction Pipeline** itself (DRP), 
* **Graphical user interfaces** for controlling pipeline operation, 
  including the :ref:`recipe_editor` and :ref:`data_parser`, a :ref:`status_console`, etc. 
* A :ref:`Calibration Database <calibdb>` that stores reduced calibration files of various types,
  and automatically provides appropriate files as needed during data processing.
* and a **customized data viewer** & analysis tool called :ref:`GPItv <gpitv>`.
  
When running, the DRP constantly looks for data to reduce, either in the form
of new FITS files (in "automatic" mode, used for real-time analysis while
observing) or new reduction "recipes" (in regular mode for
post-observing analysis). Output data, like the input, are saved as FITS files. Reduced calibration files are stored in a special
Calibrations Database directory allowing appropriate calibrations to be retrieved
automatically at each step of data reducion. As the pipeline processes data,
it can also display plots or figures on screen, or send data to the GPItv
display and data analysis tool for interactive exploration of images and
spectra. An administration console provides a status display
of the data reduction process, and keeps a log of all messages generated during
reduction. 

The most complex step in the data reduction is the conversion from 2D raw IFS
frames to 3D datacubes. Because the light from each lenslet in the IFS is
dispersed across many detector pixels, the process of uniquely assigning flux
from detector pixels back to GPI's field of view is complex. This is called
'Data-cube Extraction'. The overall process is similar for both
spectral and polarimetry modes, though algorithmic details differ. 

For each
mode (prism+filter choice), a map of the reimaged lenslet array geometry 
must be made based on observations of calibration lamps
(e.g. the locations and wavelength solutions of the ~37000 microspectra). This calibration data 
is produced from arc lamps for use in the extraction process. These
calibrations should be moderately stable, and 
obtaining the necessary lamp data is expected to be part of Gemini's facility calibrations rather than
requiring calibration by individual users. Photometric, spectral, and
polarimetric standards must be observed at night in the usual manner. The GPI
IFS Data Pipeline is designed to reduce all of this calibration data, and to
reduce scientific data to the level where an astronomer can begin custom
analyses. 


