;+
; NAME:  structDataSet Definition
;
; 	No actual IDL code here, just a structure definition.
; 	Stored in its own file to be globally available. 
;
; 	Historically, the OSIRIS pipeline which provided the
; 	foundation for the GPI one would load all images into 
; 	memory at once. We typically instead process images one
; 	at a time for reduced memory usage, because in the case of
; 	GPI we will more often be processing hour-long sequences
; 	of 60-100 images, which essentially never happens for OSIRIS.
;
; 	Hence, we just store one frame at a time in CurrFrame, 
; 	CurrUncert, and CurrDQ variables, and rely on the new
; 	AccumulateImages mechanism for the case where we want to combine images. 
; 	AccumulateImages, for the in-memory accumulation case, will use the
; 	Frames, UncertFrames, and QualFrames pointer arrays to accumultate those
; 	files, but they're not used in the case of reducing one file at a time.
;
; 	However, we do still always load all the headers at once because that's cheap. 
; 	
;
; HISTORY:
; 	Moved to its own file 2010-04-19 19:27:30 by Marshall Perrin 
; 	2011-07-29: Added HeadersPHU and HeadersExt to support Gemini MEF standard.
; 	2013-11-30 MP: Added HeadersDQ to store data quality extension headers 
;-


pro structDataset__define
	compile_opt defint32, strictarr, logical_predicate

    ; Dataset structure containing the specified input files
    ;   both filenames and data.
	MAXFRAMESINDATASETS = gpi_get_setting('max_files_per_recipe',/integer, default=1000,/silent)
     void = {structDataSet, $
            Name:'', $
            InputDir:'', $
            OutputDir:'', $
            ValidFrameCount:0, $
            FileNames:strarr(MAXFRAMESINDATASETS), $
            OutputFileNames:strarr(MAXFRAMESINDATASETS), $
            currFrame:PTR_new(/ALLOCATE_HEAP), $	; Current data to process.
            currUncert:PTR_new(/ALLOCATE_HEAP), $	; Uncertainty image for current frame
            currDQ:PTR_new(/ALLOCATE_HEAP), $ 		; Data Quality frame for current frame
            HeadersPHU:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $   ; Primary headers for all frames
            HeadersExt:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $	; SCI extension headers for all frames
            HeadersDQ:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $	; DQ extension headers for all frames
            HeadersUncert:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $	; Uncert/VAR extension headers for all frames
            Frames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $		; SCI data array for all frames (used for accumulate images)
            Wavcals:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $		;  used in microlens PSF calibration
            Polcals:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $		;  used in microlens PSF calibration
            UncertFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $ ; ERR data array for all frames (used for accumulate images)
            QualFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)}		; DQ data array for all frames (used for accumulate images)

end
