;+
; NAME: gpiPipeRun
;
; 	Start up GPI pipeline
;
;
; 	*********************************************************************
; 	*																	*
; 	*		Deprecated - please uses gpi_launch_pipeline instead		*
; 	*																	*
; 	*																	*
; 	*********************************************************************
;
; INPUTS:
; 	NONE
;
; KEYWORDS:
;
;  /noexit			Don't exit IDL after the pipeline is closed
;  /rescanDB   Create a new calibrations DB by reading all files in a given directory
;  /flushqueue		DELETE any DRFs present in the queue on startup (dangerous,
;  					mostly for debugging purposes)
;  /rescan			Rescan & recreate the calibration files DB on startup
;  /verbose     Display more output than usual, mostly for debugging
;           purposes
;  /ignoreconflict	Don't stop running if another instance is already running.
;  					Use this option at your own risk....
;  single=			Process one single DRF (provide the filename as argument)
;  					and then exit the DRP. Useful primarily for testing.
;  /nogui			Do not display the Pipeline Status Console GUI, just run the
;  					backbone algorithms.
;
; EXAMPLE:
;  IDL> gpipiperun, /noexit,  /rescanDB, /noguidrf, /parsergui
;
; HISTORY:
; 	Doc Header added 2009-04-20 by Marshall Perrin
;   2009-09-15 gui for drf added - JM 
;   2010-05-13	Removed GUI automatic startup - you can now do this via
;   			the launcher.  - MDP
;   2012-08-07 Removed ability to set nonstandard queue or config paths here -
;   			this is an unnecessary complication. -MDP
;-
PRO gpiPipeRun, _extra=_extra

	gpi_launch_pipeline, _extra=_extra

END
