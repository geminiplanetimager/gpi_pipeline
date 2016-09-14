import os
import gpipy

recipename = 'BetaPicb_SpecTest.xml'

def test_betapic(pipeline, test_dir):

    status, outrecipe, outfiles = pipeline.run_recipe( os.path.join(test_dir, recipename), rescanDB=True)

    assert status=='Success', RuntimeError("Recipe {} failed.".format(recipename))
