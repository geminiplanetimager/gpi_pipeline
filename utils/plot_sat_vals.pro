pro plot_sat_vals,lambda,sats,w=w

if (size(sats))[0] eq 2 then numim = 1 else numim = (size(sats,/dim))[2]
cols = [fsc_color('red'),fsc_color('blue'),fsc_color('green'),fsc_color('navy')]

if not(keyword_set(w)) then w = 23
window,w,xsize=800,ysize=600,retain=2 

thisLetter = "154B
greekLetter = '!4' + String(thisLetter) + '!X'

plot,/nodata,[min(lambda),max(lambda)],[min(sats),max(sats)],$
     charsize=1.5, Background=cgcolor('white'), Color=cgcolor('black'),$
     xtitle='Wavelength (' + greekLetter + 'm)',ytitle='Maximum Satellite Flux'
for k=0,numim-1 do for j=0,3 do oplot,lambda,sats[j,*,k],psym=(k mod 6)+1,color=cols[j]

end
