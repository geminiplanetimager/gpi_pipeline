
This directory contains procedures and functions which are 
	- necessary for the operation of the GPI data pipeline
	- not one of the pipeline primitives or backbone code
	- not from some publicly available IDL code library 

See the external/ directory for required routines that are from a publicly available library.


----List of routines---------

forprint2	Same as Goddard's forprint, but does not use the execute() command, in order to be compiled for the IDL runtime mode.
fxread3d	Version of fxread modified for use with datacubes? Is used by gpi_medfits, could possibly be eliminated with some reworking
