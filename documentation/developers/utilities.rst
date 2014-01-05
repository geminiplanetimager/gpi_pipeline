Utility Functions
#############################

The pipeline provides and makes use of a wide variety of utility functions for common tasks. These can be found in the ``utils`` directory.  See the
individual source code files for detailed notes and usage instructions.

The following list is *far* from complete; these are just some of the most useful functions that new developers should be aware of. 


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
	Look up a named directory's actual file path

gpi_datestr
	Get the directory 'date string' e.g. 131031 for 2013 October 31st 


FITS Files and Header Keywords
==============================================

gpi_load_fits
        Read in image extension data and primary and extension headers in one convenient function call. 

gpi_load_and_preprocess_fits
        Deprecated; this is a utility function for reading in early development GPI files with not-yet-standards-compliant
        FITS headers and updating them on the fly to match the later conventions and file formats. 

gpi_validate_file
        Validate that a file is actually suitable to process: it's from GPI and not some other Gemini instrument, etc.

gpi_get_keyword
        Get a keyword, automatically retrieving it from either Primary or Extension headers as appropriate based on the Gemini/GPI keyword specification.

gpi_set_keyword
        Set a keyword, automatically writing it to either Primary or Extension headers as appropriate based on the Gemini/GPI keyword specification.

gpi_simplify_keyword_value
        Per Gemini requirements, many GPI keywords for mechanisms have cruft on either side of the value: 
        "DISP_PRISM_G6162" instead of just "PRISM" and so on. This function trims that off and returns just the central portion.
