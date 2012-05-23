#  Set up environment variables for GPI IFS Software
#	bash version
# HISTORY:
#       2010-01-25  Created. M. Perrin
#       2010-02-01  Added IDL_DIR, enclosing quotes - M. Perrin



#----- Most users will only need to change this next line -----

export GPI_IFS_DIR="~/GPI"		# base dir for all code
export GPI_DATA_DIR="~/GPI/data"	# base dir for all data

export GPI_DRP_CONFIG_DIR="~/GPI/my_config"  # where to store my own local config settings? 


#----- Most users will not need to change anything below here -----

# where is the software?
export GPI_DRP_DIR="$GPI_IFS_DIR/pipeline"	# pipeline code location
export GPI_DRP_TEMPLATES_DIR="$GPI_IFS_DIR/drf_templates"	# pipeline DRF template location

# where is the data?
export GPI_RAW_DATA_DIR="$GPI_DATA_ROOT/Detector/"	# where is raw data?
export GPI_DRP_OUTPUT_DIR="$GPI_DATA_ROOT/Reduced/"	# where should we put reduced data?
export GPI_DRP_QUEUE_DIR="$GPI_DATA_ROOT/queue/"	# where is the DRP Queue directory?
export GPI_DRP_LOG_DIR="$GPI_DATA_ROOT/logs/"	# default log dir

#---------- make sure the startup scripts are in your $PATH   -----
export PATH="${PATH}:${GPI_DRP_DIR}/scripts"
export IDL_PATH="${IDL_PATH}:+${GPI_IFS_DIR}"
