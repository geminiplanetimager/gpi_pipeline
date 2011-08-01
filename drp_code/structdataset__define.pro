;+
; NAME:  structDataSet Definition
;
; 	No actual IDL code here, just a structure definition.
; 	Stored in its own file to be globally available. 
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Moved to its own file 2010-04-19 19:27:30 by Marshall Perrin 
; 	2011-07-29: Added HeadersPHU and HeadersExt to support Gemini MEF standard.
;-


pro structDataset__define
    ; Dataset structure containing the specified input files
    ;   both filenames and data.
	MAXFRAMESINDATASETS = 550
     void = {structDataSet, $
            Name:'', $
            InputDir:'', $
            OutputDir:'', $
            ValidFrameCount:0, $
            FileNames:strarr(MAXFRAMESINDATASETS), $
            OutputFileNames:strarr(MAXFRAMESINDATASETS), $
            currFrame:PTR_new(/ALLOCATE_HEAP), $
            Frames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            HeadersExt:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            HeadersPHU:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            ErrFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            QualFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)}
end
