import inspect
import os

import gpipy

import pytest


# Test fixtures for GPI pipeline testing. 
# This file containts common test infrastructure functions which should
# be made available to all of the individual tests, via the py.test
# Fixtures functionality.

__all__ = ['pipeline', 'test_dir', 'patch_pipeline_dir_env_vars']

@pytest.fixture(scope="module")
def pipeline(request):
    """Fixture for preparing a handle to the pipeline. This returns an
    instance that can be used to run a given recipe."""
    pipeline = gpipy.PipelineDriver()
    return pipeline


@pytest.fixture
def test_dir(request):
    """Fixture for returning directory name of a given test,
    and making that the current working directory.
    
    This is used to ensure that pipeline outputs
    """
    dirname = os.path.dirname(str(request.fspath))
    os.chdir(dirname)
    return dirname

@pytest.fixture(autouse=True)
def patch_pipeline_dir_env_vars(monkeypatch,request):
    """ Override default directories with test directories"""

    # Write pipeline log files to the local directory for each test

    monkeypatch.setenv("GPI_DRP_LOG_DIR",  os.path.dirname(str(request.fspath)) )

    # Use a special directory for calibrations, set up to support these tests

    gpiesroot = os.getenv("GPIES_DROPBOX_ROOT")
    if gpiesroot is not None:

        # Each test directory set up here in git has a corresponding directory
        # on Dropbox, which contains the relevant input data file and calibration
        # files. Figure out the directory name used for the python test file:
        mydirname = os.path.basename(os.path.dirname(str(request.fspath)))
        # and from that set the CALIBRATIONS_DIR to the corresponding one

        my_cal_dir = os.path.join(gpiesroot,"Pipeline_Releases","pipeline_testing_dataset", mydirname)
        monkeypatch.setenv("GPI_CALIBRATIONS_DIR", my_cal_dir)
