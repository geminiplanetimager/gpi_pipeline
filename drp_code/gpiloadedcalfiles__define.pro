;+
; NAME:  
;
; INPUTS:
; KEYWORDS:
; OUTPUTS:
;
; HISTORY:
; 	Began 2010-05-22 13:35:56 by Marshall Perrin 
;   JM: corrected bug in gpiloadedcalfiles::get
;-


pro gpiloadedcalfiles::load, filename, type

	; find a slot to load a cal file into
	wm = where(self.filetypes eq type, mct)
	if mct eq 0 then begin
		wempty = where(self.filetypes eq '', emptyct)
		if emptyct eq 0 then message, "Ran out of memory slots to load cal files!"
		wm = wempty[0]
	endif
	wm = wm[0]

	; check if this one's already loaded
	if self.filenames[wm] eq filename then begin
		message, "Calibration file "+filename+" is already loaded into memory; no need to reload.",/info
		return
	endif else begin
		if ~ file_test(filename) then message, "ERROR: requested file does not exist: "+filename

		data = readfits(filename, header)
		*(self.data[wm]) = data
		*(self.headers[wm]) = header

		self.filenames[wm] = filename
		self.filetypes[wm] = type
	endelse



end

;------------------

function gpiloadedcalfiles::get, type, header=header, filename=filename

	; find a slot with the requested type of cal file 
	wm = where(self.filetypes eq type, mct)
	if mct eq 0 then begin
		message, "No cal file of type "+type+ "is loaded yet."
	endif
	wm = wm[0]

	header = *(self.headers[wm])
	;filename= *(self.filenames[wm])
	 filename= (self.filenames[wm]) ;JM changed pointer=>string
	return, *(self.data[wm])


end

;------------------
function gpiloadedcalfiles::init
	nmax = n_elements(self.filenames)
	self.data = ptrarr(nmax,/alloc)
	self.headers = ptrarr(nmax,/alloc)

return, 1
end


;------------------

pro gpiloadedcalfiles__define

nmax = 10 ; max calib files to load at once?

str = {gpiloadedcalfiles, $
		filenames: strarr(nmax), $
		filetypes: strarr(nmax), $
		data: ptrarr(nmax), $
		headers: ptrarr(nmax)}

end
