function gpirootdir,group,proj
	compile_opt hidden
	return,getenv('GPI_ROOT_DIR_PREFIX')+group+$
		getenv('GPI_ROOT_DIR_POSTFIX')+proj
end
