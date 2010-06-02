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
;-


pro structDataset__define
    ; Dataset structure containing the specified input files
    ;   both filenames and data.
	MAXFRAMESINDATASETS = 550
     void = {structDataSet, $
            Name:'', $
            FileNames:strarr(MAXFRAMESINDATASETS), $
            OutputFileNames:strarr(MAXFRAMESINDATASETS), $
            InputDir:'', $
            OutputDir:'', $
            ValidFrameCount:0, $
            ;currFrame:PTRARR(1, /ALLOCATE_HEAP), $
            currFrame:PTR_new(/ALLOCATE_HEAP), $
            Frames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            Headers:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            ErrFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP), $
            QualFrames:PTRARR(MAXFRAMESINDATASETS, /ALLOCATE_HEAP)}
end
