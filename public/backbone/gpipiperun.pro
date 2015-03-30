;+
; NAME: gpiPipeRun
;
; 	Start up GPI pipeline
;
; 	*********************************************************************
; 	*																	*
; 	*		Deprecated - please uses gpi_launch_pipeline instead		*
; 	*																	*
; 	*																	*
; 	*********************************************************************
;-
PRO gpiPipeRun, _extra=_extra

	gpi_launch_pipeline, _extra=_extra

END
