pro sxaddparlarge, Header, Name, Value
;+
; NAME:
;       SXADDPARlarge
; PURPOSE:
;       Add  a 'COMMENT' or 'HISTORY' parameter in a FITS header array.
;        If the length of the element is greater than 80, the element is splitted 
;
; CALLING SEQUENCE:
;       SXADDPAR, Header, Name, Value
;
; INPUTS:
;       Header = String array containing FITS or STSDAS header.    The
;               length of each element can be greater than 80 characters.    If not 
;               defined, then SXADDPAR will create an empty FITS header array.
;
;       Name = Name of parameter. If Name is already in the header the value 
;               and possibly comment fields are modified.  Otherwise a new 
;               record is added to the header.  If name is equal to 'COMMENT'
;               or 'HISTORY' or a blank string then the value will be added to 
;               the record without replacement.  For these cases, the comment 
;               parameter is ignored.
;
;       Value = Value for parameter.  The value expression must be of the 
;               correct type, e.g. integer, floating or string.  String values
;                of 'T' or 'F' are considered logical values.
;
; OUTPUTS:
;       Header = updated FITS header array.
;
; RESTRICTIONS:
;       Warning -- Parameters and names are not checked
;               against valid FITS parameter names, values and types.
;
; MODIFICATION HISTORY:
;       JM: use it when the length is greater than 80
;       
;- 

        IF STRLEN(Value) LT 72 THEN BEGIN
          SXADDPAR, header, Name, Value
        ENDIF ELSE BEGIN
          ; Figure out how many 80 character strings there are in the current string
          clen = STRLEN(Value)
          n = (clen/72) + 1
          FOR j=0, n-1 DO BEGIN
            newsubstring = STRMID(Value, j*72, 72)
            SXADDPAR, header, Name,  newsubstring
          ENDFOR
        ENDELSE
end