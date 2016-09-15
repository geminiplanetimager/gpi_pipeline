import os
import gpipy

recipename = 'HR4796_PolTest.xml'
nfiles_expected = 14


def test_betapic(pipeline, test_dir):

    status, outrecipe, outfiles = pipeline.run_recipe( os.path.join(test_dir, recipename), rescanDB=True)

    # did the pipeline run without error?
    assert status=='Success', "Recipe {} failed to execute".format(recipename)

    # Did we get the output files we expected?
    assert len(outfiles)==nfiles_expected, "Number of output files does not match expected value."
    assert "./S20140422S0291_stokesdc.fits" in outfiles, "Output files didn't contain the expected Stokes cube"

    # Are the contents of that file what we expected?
    cube = gpipy.read("./S20140422S0291_stokesdc.fits")
    assert cube.filetype=='Stokes Cube', "Wrong output file type"
    assert cube.shape[0]==4, "Wrong cube dimensions"

    # TODO write more tests here looking at actual pixel values

