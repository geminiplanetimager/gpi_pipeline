
# GPI DRP automated testing

This directory implements automated tests for the GPI Data Reduction Pipeline



## Running tests

This test setup is a work in progress, aimed at members of the GPIES team. It assumes you have access to the
GPIES team Dropbox area, in which we store data files for tests.  Anyone outside the GPI team who is interested in
helping with test development or running these tests themselves should contact Kate Follette or Marshall Perrin.

1. Ensure your copy of the GPIES dropbox is syncing the top-level folder "Pipeline_Releases"

2. Define an environment variable ``$GPIES_DROPBOX_ROOT`` to point to the file
    path of your installed copy of the Dropbox (GPI) folder. This will probably be
    something like "/Users/yourusername/Dropbox (GPI)" on mac OS, but may differ
    depending on your installation choices. (I.e. this variable should point to the
    parent directory containing the "Pipeline_Releases" directory mentioned just
    above.)

3. You run the test suite by changing to the tests directory and invoking py.test from the command line:

```
  cd pipeline/tests
  py.test
```

4. After all tests run (which will take a few minutes), pytest will output the
    number of passed (or failed) tests.  Test output files (FITS files, contrast
    curves, and pipeline log files) will be written into each of the ``test_n``
    subdirectories. You can manually examine them if desired. 




## Writing a new test

Tests are defined by a directory containing a GPI pipeline reduction recipe and a python test script
compatible with the pytest framework, plus a separate matching directory containing the relevant FITS files.

To write a new test:

1. Make a new directory with a unique test name. For this example, we
    will call it "mytest".
    ```%> mkdir test_mytest
    ```

2. Copy ``test_spec/test_spec.py`` as a template.
```%> cp test_spec/test_spec.py test_mytest/test_mytest.py
```

3. Make an XML Recipe file to process raw data into the cube(s) you will use
    for testing. See ``test_spec/test_spec.xml`` as an example. You can make these
    in the usual way with the GPI Recipe Editor.  Note, you should try to name the
    recipe file to match the test case name.

    You should then manually edit that recipe to customize a few  directory paths. 
    In particular, set the input directory using the ``$GPIES_DROPBOX_ROOT`` environment
    variable, and set the output directory to ``"."``:
    ```
    InputDir="${GPIES_DROPBOX_ROOT}/Pipeline_Releases/pipeline_testing_dataset/test_pol" OutputDir="."
    ```

4a. Please **do not** check any FITS files into the git repository. Instead,
    place them inside ``Dropbox (GPI)/Pipeline_Releases/pipeline_testing_dataset/test_mytest``. 
    The directory name here on Dropbox *must* exactly match the name of the directory created in
    the source code tests in step 1 above. 

4b. You should also create a subdirectory ``cal_files`` inside that directory on Dropbox. Place inside it
    ALL calibration files required to reduce your test dataset. Note that no other files in
    your usual pipeline calibrations directory will be visible or accessible to the test suite! This
    is necessary to ensure precise repeatability of tests.

5. Edit your new file ``test_mytest.py`` to set the ``recipename`` variable to
    the name of the XML file you just created. If desired, modify the test function to
    add any additional test assertions which you want to apply to the output files. 

6. Try running your test:  
    ```%> cd pipeline/tests
    %> py.test test_mytest 
    ```
    Iterate, adjusting the test setup as needed until the test passes as desired.

7. Check in the recipe XML file and Python test function file into git.
    ```%> git add test_mytest
    %> git commit -m "Adding a new test: mytest"
    ```


## Requirements

Python packages:
 * pytest
 * astropy
 * gpipy (not on PyPI, must install from https://github.com/geminiplanetimager/gpipy/)

The test data assumes you have access to the GPI Exoplanet Survey shared Dropbox area. 

And a working copy of the latest GPI data reduction pipeline of course. 


## Credits

By Kate Follette and Marshall Perrin

Inspired by and partially adapted from the Keck OSIRIS DRP
unit tests: https://github.com/Keck-DataReductionPipelines/OsirisDRP/tree/develop



