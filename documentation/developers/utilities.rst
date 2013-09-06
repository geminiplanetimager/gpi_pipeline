Utility Functions
#############################

Pipeline Configuration Settings
==========================================

gpi_get_setting
        Load values from config files by calling::
            setting = gpi_get_setting('name_of_desired_setting', default='value if setting not in config file')

        Add a keyword to /integer, /float, /bool etc if you want to cast to some non-string type. 


Data Paths and Filenames
==========================================

gpi_expand_path
	Utility function for expanding pathnames, ~ and ~username, environment variables, etc.

gpi_shorten_path
	Inverse of the above: compress any strings to environment variables if possible.

gpi_get_directory
	Look up a named directory’s actual file path

gpi_datestr
	Get the directory ‘date string’ e.g. 131031 for 2013 October 31st 


FITS Files and Header Keywords
==============================================

gpi_load_fits
gpi_load_and_preprocess_fits
gpi_validate_file

gpi_get_keyword
gpi_set_keyword
gpi_simplify_keyword_value
