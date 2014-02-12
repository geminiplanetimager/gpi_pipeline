;+
; NAME:  gpi_compare_wavecals
;
; INPUTS:
;	file1, file2	Names of 2 wavecal FITS files
; KEYWORDS:
;	charsize		character size for labeling plots
; OUTPUTS:
;
;	Plots comparing the properties of the two wavecals are displayed on screen.
;
; HISTORY:
;	Began 013-12-03 11:05:04 by Marshall Perrin 
;-

PRO gpi_compare_wavecals, file1, file2, charsize=charsize


if ~(keyword_set(charsize)) then charsize=2

wc1 = gpi_readfits(file1, header=header1, priheader=priheader1)
wc2 = gpi_readfits(file2, header=header2, priheader=priheader2)

band1 = gpi_simplify_keyword_value(sxpar(priheader1, 'IFSFILT'))
inttime1 = sxpar(header1, 'ITIME')
lamp1 = strc(sxpar(priheader1, 'GCALLAMP'))
date1 = strc(sxpar(priheader1, 'DATE-OBS'))
band2 = gpi_simplify_keyword_value(sxpar(priheader2, 'IFSFILT'))
inttime2 = sxpar(header2, 'ITIME')
lamp2 = strc(sxpar(priheader2, 'GCALLAMP'))
date2 = strc(sxpar(priheader2, 'DATE-OBS'))


!y.omargin=[0,9]
!p.multi = [0,2,2]

plothist, wc1[*,*,0]-wc2[*,*,0],/nan,bin=0.01,/ylog,title='Differences in Y', xtitle="Mean: "+sigfig( mean(wc2[*,*,0]-wc1[*,*,0],/nan),3)+" pix"
plothist, wc1[*,*,1]-wc2[*,*,1],/nan,bin=0.01,/ylog,title='Differences in X', xtitle="Mean: "+sigfig( mean(wc2[*,*,1]-wc1[*,*,1],/nan),3)+" pix"
plothist, wc1[*,*,3]-wc2[*,*,3],/nan,bin=0.00001,/ylog,title=textoidl('Differences in dispersion'), xtitle="Mean: "+sigfig( mean(wc2[*,*,3]-wc1[*,*,3],/nan),3)+" um/pix"
plothist, wc1[*,*,4]-wc2[*,*,4],/nan,bin=0.01,/ylog,title=textoidl('Differences in theta'), xtitle="Mean: "+sigfig( mean(wc2[*,*,4]-wc1[*,*,4],/nan),3)+" rad"


xyouts, 0.1, 0.95, file1 + ":   "+band1+"  "+lamp1+", "+strc(fix(round(inttime1)))+ " s on "+date1,/normal, charsize=charsize
xyouts, 0.1, 0.9, file2 + ":   "+band2+"  "+lamp2+", "+strc(fix(round(inttime2)))+ " s on "+date2,/normal, charsize=charsize
xyouts, 0.1, 0.85, "    Histograms show first file minus second file.",/normal,charsize=charsize


!y.omargin=0

stop

end
