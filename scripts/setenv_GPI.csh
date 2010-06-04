#  Set up environment variables for GPI IFS Software
#	csh/tcsh version
# HISTORY:
#       2010-01-25  Created. M. Perrin
#       2010-02-01  Added IDL_DIR, enclosing quotes - M. Perrin



#----- Most users will only need to change this next line -----

setenv GPI_IFS_DIR "~/GPI"	# base dir for all code



#----- Most users will not need to change anything below here -----

# where is the software?
setenv GPI_PIPELINE_DIR "$GPI_IFS_DIR/pipeline/"	# pipeline software
setenv GPI_PIPELINE_LOG_DIR "$GPI_IFS_DIR/logs/"		# default log dir
setenv GPI_DRF_TEMPLATES_DIR "$GPI_PIPELINE_DIR/drf_templates/"	# template Data Reduction Files
setenv GPI_QUEUE_DIR "$GPI_PIPELINE_DIR/queue/"		# DRF Queue directory
setenv GPI_CONFIG_FILE "$GPI_PIPELINE_DIR/dpl_library/drsConfig.xml"

# where is the data?
setenv GPI_RAW_DATA_DIR "$GPI_IFS_DIR/data/raw/"
setenv GPI_DRP_OUTPUT_DIR "$GPI_IFS_DIR/data/reduced/"

# make sure the startup scripts are in your $PATH
setenv PATH "${PATH}:${GPI_PIPELINE_DIR}scripts"
setenv IDL_PATH "${IDL_PATH}:+${GPI_IFS_DIR}"
