#  Set up environment variables for GPI IFS Software
#	bash version
# HISTORY:
#       2010-01-25  Created. M. Perrin
#       2010-02-01  Added IDL_DIR, enclosing quotes - M. Perrin



#----- Most users will only need to change this next line -----

export GPI_IFS_DIR="~/GPI"		# base dir for all code



#----- Most users will not need to change anything below here -----

# where is the software?
export GPI_DRP_DIR="$GPI_IFS_DIR/pipeline/"	# pipeline software
export GPI_DRP_LOG_DIR="$GPI_IFS_DIR/logs/"		# default log dir
export GPI_DRP_TEMPLATES_DIR="$GPI_DRP_DIR/drf_templates/"	# template Data Reduction Files
export GPI_DRP_QUEUE_DIR="$GPI_DRP_DIR/queue/"		# DRF Queue directory
export GPI_DRP_CONFIG_DIR="$GPI_DRP_DIR/dpl_library/drsConfig.xml"

# where is the data?
export GPI_RAW_DATA_DIR="$GPI_IFS_DIR/data/raw/"
export GPI_DRP_OUTPUT_DIR="$GPI_IFS_DIR/data/reduced/"

# make sure the startup scripts are in your $PATH
export PATH="${PATH}:${GPI_DRP_DIR}/scripts"
export IDL_PATH="${IDL_PATH}:+${GPI_IFS_DIR}"
     
