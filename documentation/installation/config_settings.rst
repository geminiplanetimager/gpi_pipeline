
.. _config_settings:

Appendix: Configuration File Settings
=========================================

This appendix describes the various configuration parameters that may be adjusted in the pipeline's configuration settings text files.
The settings are organized here into several tables grouping them by subject matter, but in the config file they may be listed in any order.


For boolean variables in the following, 0=False and 1=True in the usual fashion.


Some of the following will be of general interest and many users may wish to change their values; others are mostly of interest for 
development and debugging.


Settings related to data & directory organization
-----------------------------------------------------

======================================  ==============================  =============   ====================================================================================
Setting Name                            Possible Values                 Default Value   Meaning
======================================  ==============================  =============   ====================================================================================
organize_raw_data_by_dates              0,1                             1               Should we expect raw data to be organized in directories by date underneath 
                                                                                        $GPI_RAW_DATA_DIR? If so, data should be in directories named 
                                                                                        according to YYMMDD such as 130401 for 2013 April 01.
organize_reduced_data_by_dates          0,1                             1               Should reduced data be output in directories organized by data under 
                                                                                        $GPI_DRP_OUTPUT_DIR? Such directories will be created if needed. 
organize_recipes_by_dates               0,1                             1               Should saved DRFs be output in directories organized by data under 
                                                                                        $GPI_DRP_OUTPUT_DIR? Such directories will be created if needed. 
prompt_user_for_outputdir_creation      0,1                             0               If set to zero, whenever you need to create a directory to save some requested 
                                                                                        filename (e.g. for storing output files or DRFs), just go ahead and do so without 
                                                                                        asking the user about it. If set, ask the user first before creating the directory.
apodizer_spec                           <string>                        See at right.   Full path to apodizer_spec file.  Defaults to "$GPI_DRP_CONFIG_DIR/apodizer_spec.txt"

======================================  ==============================  =============   ====================================================================================



Settings related to pipeline software behavior
-------------------------------------------------

======================================  ==============================  =============   ==============================================================================================
Setting Name                            Possible Values                 Default Value   Meaning
======================================  ==============================  =============   ==============================================================================================
strict_validation                       0,1                              1              Strictly enforce checking of input data - any data which does not validate OK as 
                                                                                        a GPI file is ignored. If turned off (0), will attempt to preprocess files to 
                                                                                        fix missing keyword headers etc during I&T so the data can be processed anyway.
parsergui_auto_queue                    0,1                              0              Should the Parser GUI automatically add to the queue the DRFs that it produces?
prompt_user_for_questionable_data       0,1                              Unused?        if set, when the pipeline encounters a "questionable" (aborted/lousy seeing/otherwise 
                                                                                        flagged as bad DQ) frame, it should ask the user whether to process that file or not. 
                                                                                        If this is not set, the pipeline will silently discard the file.
file_overwrite_handling                 overwrite,ask,append            ask             How should the pipeline act when it tries to output a file but a file with that filename
                                                                                        already exists on disk? Depending on this option it will either 'ask' the user for
                                                                                        confirmation before overwriting and offer a chance to choose a different filename,
                                                                                        'append' a number to the filename to generate a new unique filename such that both
                                                                                        the old and new file will remain on disk, or 'overwrite' to just overwrite the existing file.
force_rescan_config_on_startup          0,1                              0              When you start the pipeline, force an automatic rescan of the pipeline primitives
                                                                                        and other settings. (Regenerate the index of available primitives, compile all, etc.)
                                                                                        Equivalent to pressing the Rescan Config button on the Status Console. a
force_rescan_caldb_on_startup           0,1                              0              Force a re-scan and re-indexing of all FITS files in the calibration database when the
                                                                                        pipeline starts. Potentially takes a long time, but will ensure you make use of all
                                                                                        available calibration files if someone has e.g. copied or moved files into that directory 
                                                                                        manually outside of the pipeline itself. 
username_in_log_filename                0,1                             0               Should the username of the user running the pipeline be included in log filename, as well
                                                                                        as the date? This is useful on shared installations on multiuser machines so that different
                                                                                        users' log files don't overwrite one another.
launcher_force_semaphore_name           <string>                        See at right.   Name of semaphore used for the inter-IDL communication queue lock. Sometimes the lock is not 
                                                                                        properly released so this setting should be specified with a different name so that a 
                                                                                        different lock name can be used for the queue. Default is "GPI_DRP_$USER"
======================================  ==============================  =============   ==============================================================================================



Settings for GPItv
----------------------

All of the following GPITV settings can also be adjusted for each individual GPItv window at any time using the Options menu. Setting their
values in the pipeline configuration file controls the default settings that will be used for newly opened GPItv windows.

======================================  ==============================  =============   ====================================================================================
Setting Name                            Possible Values                 Default Value   Meaning
======================================  ==============================  =============   ====================================================================================
gpitv_default_scale                     linear, log, sqrt,               log            Sets the default image scale for newly opened gpitv windows 
                                        asinh, histeq           
gpitv_retain_current_slice              0,1                              1              1: Open new images to the same slice as current image is on. 
                                                                                        0: Open all images to the same default slice.
gpitv_retain_current_zoom               0,1                              1              Toggle auto zoom + recenter or keep same zoom + position for newly loaded images.
gpitv_retain_current_stretch            0,1                              0              Toggle autoscaling of display stretch for newly loaded images.
gpitv_auto_handedness                   0,1                              1              Toggle whether to automatically flip images if needed to have East
                                                                                        counterclockwise of North. Has no effect is retain_current_zoom is 1. 
gpitv_showfullpaths                     0,1                              0              Toggle to show the full path to files in the gpitv titlebar.
gpitv_noinfo                            0,1                              0              Toggle suppression of informational messages.
gpitv_nowarn                            0,1                              0              Toggle suppression of warning messages.
gpitv_startup_dir                       path                             None           Set the initial input/output directory for new GPItv instances.  If unset, GPItv defaults to your current working directory.
======================================  ==============================  =============   ====================================================================================




Debug and Development Related Options
-------------------------------------------------

These are documented here for completeness, but it's not expected that many users will need to
change any of the following very often. 

======================================  ==============================  =============   ==============================================================================================
Setting Name                            Possible Values                 Default Value   Meaning
======================================  ==============================  =============   ==============================================================================================
max_files_per_recipe                       <integer>                    1000            Maximum number of input FITS files allowed in a single data reduction recipe. 
                                                                                        This is used to allocate some internal arrays. Default is 200, but can be made 
                                                                                        arbitrarily larger if needed, memory permitting.
parsergui_max_files                       <integer>                     1000            Maximum number of files that can be loaded in the data parser at one time.
                                                                                        This is used to allocate some internal arrays. Default is 1000, but can be made 
                                                                                        arbitrarily larger if needed, memory permitting.
enable_primitive_debug                  0,1                              0              If set, IDL code errors in primitives will stop at a breakpoint, rather than continuing 
                                                                                        execution of the pipeline and just marking that recipe file as failed. Only applicable
                                                                                        if you are running from source code.
enable_gpitv_debug                      0,1                              0              If set, IDL code errors in gpitv will stop at a breakpoint, rather than returning to main
                                                                                        scope. Only applicable if you are running from source code.
enable_parser_debug                     0,1                              0              Enable more verbose debugging output from data parser.
drp_queue_poll_freq                     float                            1.0            Frequency that the data pipeline will poll the queue directory for new recipes, in 
                                                                                        Hertz. Default is 1.
drp_gui_poll_freq                       float                            10             Frequency that the data pipeline status console will check for user interaction during 
                                                                                        polling, in Hertz. Default is 10. This only applies to the Status Consolue GUI, since it's 
                                                                                        the only GUI that runs in the pipeline IDL session as opposed to the GUI IDL session. 
prevent_multiple_instances              0,1                             0               Attempt to check for and prevent launching multiple copies of the pipeline running on one
                                                                                        computer.   
preprocess_fits_files                   0,1                             0               Attempt to compensate for early GPI development FITS files that lack standard FITS headers
======================================  ==============================  =============   ==============================================================================================



