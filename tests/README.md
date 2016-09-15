
# GPI DRP automated testing

This directory implements automated tests for the GPI Data Reduction Pipeline



## Running tests

This test setup is a work in progress, aimed at members of the GPIES team. It assumes you have access to the
GPIES team Dropbox area, in which we store data files for tests.  Anyone outside the GPI team who is interested in
helping with test development or running these tests themselves should contact Kate Follette or Marshall Perrin.

1. Ensure your copy of the GPIES dropbox is syncing the top-level folder "Pipeline_Releases"

2. Define an environment variable ``$GPIES_DROPBOX_ROOT`` to point to the file path of your installed copy of
the Dropbox (GPI) folder. This will probably be something like "/Users/yourusername/Dropbox (GPI)" on mac OS, but may
differ depending on your installation choices. 

3. You run the test suite by changing to the tests directory and invoking py.test from the command line:

```
  cd pipeline/tests
  py.test
```




## Writing a new test

To write a new test, follow these instructions.

1. Make a new directory with a unique test name. For this example, we
will call it "mytest".
```%> mkdir test_mytest
```

2. Copy ``test_spec/test_spec.py`` as a template.
```%> cp test_spec/test_spec.py test_mytest/test_mytest.py
```

3. Make an XML Recipe file to process raw data into the cube(s) you will use for
testing. See ``test_spec/test_spec.xml`` as an
example. You can make these in the usual way with the GPI Recipe Editor. 
Note, you should try to name the recipe file to match the test
case name.


4. Please **do not** check any FITS files into the git repository. Instead, place them
inside ``Dropbox (GPI)/Pipeline_Releases/pipeline_testing_dataset/test_mytest``.
You should also create a subdirectory ``cal_files`` inside that directory which contains 
ALL calibration files required to reduce that dataset. Note that no other files in
your usual pipeline calibrations directory will be visible or accessible to the test suite!

5. Edit your new file ``test_mytest.py`` to set the ``recipename`` variable to
the name of the XML file you just created. If desired, modify the test function to
add any additional test assertions which you want to apply to the output files. 

6. Try running your test:  
```%> cd pipeline/tests
%> py.test test_mytest 
```
Iterate, adjusting the test setup as needed until the test passes as desired.

7. Check in all of your files into git.
```%> git add test_mytest
%> git commit -m "Adding a new test: mytest"
```


## Requirements

Python packages:
 * pytest
 * astropy
 * gpipy (not on PyPI, must install from https://github.com/geminiplanetimager/gpipy/)

The test data assumes you have access to the GPI Exoplanet Survey shared Dropbox area. 


## Credits

By Kate Follette and Marshall Perrin

Inspired by and partially adapted from the Keck OSIRIS DRP
unit tests: https://github.com/Keck-DataReductionPipelines/OsirisDRP/tree/develop



