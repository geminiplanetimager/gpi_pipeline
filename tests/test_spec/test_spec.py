import os
import gpipy

recipename = 'BetaPicb_SpecTest.xml'
nfiles_expected = 11

def test_betapic(pipeline, test_dir):
    """ End to end test for GPI spectral reductions

    Reduce GPI first light Beta Pic b dataset, combine
    individual cubes together via a simple median,
    (no PSF sub is needed for Beta Pic b here!),
    and detect the planet.
    """

    status, outrecipe, outfiles = pipeline.run_recipe( os.path.join(test_dir, recipename), rescanDB=True)

    assert status=='Success', RuntimeError("Recipe {} failed.".format(recipename))

    # Did we get the output files we expected?
    assert len(outfiles)==nfiles_expected, "Number of output files does not match expected value."
    assert "./S20131118S0064_median.fits" in outfiles, "Output files didn't contain the expected median cube"

    # Are the contents of that file what we expected?
    cube = gpipy.read( "./S20131118S0064_median.fits")
    assert cube.filetype=='Spectral Cube', "Wrong output file type"

    # TODO write tests here that check sat spot keyword values in headers for one of the individual files

    # TODO write more tests here looking at actual pixel values, to
    # verify the planet is detected as expected

