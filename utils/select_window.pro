;+
; NAME: select_window 
;
;	Choose an output window to display some graphics in. 
;	If the window is not already open, open it. 
;	If it is, then just switch to it. 
;
;	This is a simple script to work around the lame behavior of ]
;	IDL's default window and wset commands
;
; INPUTS:
;	num		window ID number
; KEYWORDS:
;	/show	set to raise the window to the foreground (wshow)
; OUTPUTS:
;
; HISTORY:
;	Began 2013-04-25 16:50:07 by Marshall Perrin as a
;	stripped-down version of win.pro by M. Liu and M. Perrin
;	from about a decade ago.
;	 
;-


pro select_window, num, show=show

   Device, Window_State=theseWindows
    if (theseWindows[num] eq 1) then begin
        wset,num
        if keyword_set(show) then wshow
        return
    endif else window, num


end
