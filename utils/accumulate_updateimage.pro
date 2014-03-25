;+
; NAME:  accumulate_updateimage
; DESCRIPTION: Update or replace one of the images saved by Accumulate_Images
;		
;		To be used as an setter routine inside any primitive that 
;		needs to access and set multiple files already in the accumulator.
;
;		Note that if images were accumulated 'OnDisk', this does **NOT** update
;		or overwrite the files on disk. Rather it switches to in memory
;		accumulation for the modified files. 
;
; INPUTS:
;	dataset		The dataset structure
;	index		The index of the file to modify
;	newdata		Replacement data array (cube or image)
;	newhdr		Replacement primary HDU header
;	newexthdr	Replacement extension HDU header
; OUTPUTS:
;
; 	Began 2014-03-20 by Marshall Perrin 
;-

PRO accumulate_updateimage, dataset, index, newdata=newdata, newhdr=newhdr, newexthdr=newexthdr
	common PIP
	common APP_CONSTANTS

	compile_opt defint32, strictarr, logical_predicate

	; Retrieve whatever is in the accumulator now
	olddata = accumulate_getimage(dataset, index, oldhdr, hdrext=oldexthdr)

	; Replace some part(s) of it
	if ~(keyword_set(newdata))   then newdata = olddata
	if ~(keyword_set(newhdr))	 then newhdr  = oldhdr
	if ~(keyword_set(newexthdr)) then newexthdr = oldexthdr

	; Store the result back into the dataset
	*(dataset.frames[index]) = newdata	
    *(dataset.headersPHU[index]) = newhdr
    *(dataset.headersExt[index]) = newexthdr


end
