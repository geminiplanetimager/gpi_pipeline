function Strc, thing,print=print,join=join,format=format,delimiter=delimiter,$
	nantonull=nantonull

;+
; function Strc, thing,print=print,join=join
; PURPOSE: 
; Formats something as a string, 
; removing the extra spaces and unnecessary zeros. 
; Works on scalars or arrays.
;
;KEYWORDS:
;	print=		the print argument for string. See IDL help for string
;	/join		if argument is an array, contatenate the output into
;				a single string, using a space as delimiter.
;	delimiter=  When /join is set, use this to join the strings instead
;				of just a space.
;
;HISTORY:
; will choke on arrays, only works on scalars
; June 1994, M. Liu (UCB)
;
; added chopping of unneeded zeros on the end of floats/doubles
; (beware if numbers are too long, will be chopped off - this is
; and IDL feature of the 'string' command, not due to this function)
; 11/05/96 MCL
;
; Added ability to pass the "print" argument to string
; 2001-07-09 MDP
;
; Added /join
; 2003-07-01 MDP
;
; 2004-04-06	Fixed horrible, horrible bug with scientific notation
; 				How did I ever not notice this before now?!?? MDP
; 2005-07-22	Added /delimiter
;-
;###########################################################################
;
; LICENSE
;
; This software is OSI Certified Open Source Software.
; OSI Certified is a certification mark of the Open Source Initiative.
;
; Copyright © 1994-2003 by Michael Liu & Marshall Perrin
;   
; This software is provided "as-is", without any express or
; implied warranty. In no event will the authors be held liable
; for any damages arising from the use of this software.
;   
; Permission is granted to anyone to use this software for any
; purpose, including commercial applications, and to alter it and
; redistribute it freely, subject to the following restrictions:
;   
; 1. The origin of this software must not be misrepresented; you must
;    not claim you wrote the original software. If you use this software
;    in a product, an acknowledgment in the product documentation
;    would be appreciated, but is not required.
;   
; 2. Altered source versions must be plainly marked as such, and must
;    not be misrepresented as being the original software.
;   
; 3. This notice may not be removed or altered from any source distribution.
;   
; For more information on Open Source Software, visit the Open Source
; web site: http://www.opensource.org.
;   
;###########################################################################
    
	on_error,2


if n_params() eq 0 then return, ''

if not(arg_present(print)) then print=0

sz = size(thing)
typ = sz(sz(0)+1)

; convert NaNs to 'NULL'. This is useful for sticking them into a
; SQL database.
if keyword_set(nantonull) then begin
	if finite(thing,/NAN) then return,"NULL" 
	; Also translate Infs and other such things.
	if ~finite(thing) then return,"NULL" 
		
endif

if sz(0) eq 0 then begin 

    ; round any floats of their excess zeros,
    ; putting a zero at the end if there's an exposed decimal pt
    ; -> only works for scalars, not vectors
    ; -> this screws up sci notation, e.g. '1e10' becomes '1e1'
    typ = sz(0)+1
	
	; fixed to NOT screw up scientific notation. MDP
;	pow = floor(alog10(thing))
;	num = thing/10.^pow
num=thing
ss = strcompress(string(num,print=print,format=format), /remove_all)
;	if (sz(typ) eq 5) or (sz(typ) eq 4) then begin
;		while (strmid(ss,strlen(ss)-1,1) eq '0') do begin
;			ss = strmid(ss,0,strlen(ss)-1)
;		endwhile
;	if (strmid(ss,strlen(ss)-1,1) eq '.') then ss = ss+'0'
;	endif
;	if (pow ne 0) then $
;		ss = ss+"e"+strcompress(string(pow),/remove_all)


endif else $
  ss =  strcompress(string(thing, print=print,format=format), /remove_all)

if keyword_set(join) then begin
	if ~(keyword_set(delimiter)) then delimiter=" "
	ss = strjoin(ss,delimiter,/single)
endif
return,ss   
;return, strcompress(string(thing), /remove_all) 


end
