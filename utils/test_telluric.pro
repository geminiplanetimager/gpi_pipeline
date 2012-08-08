pro test_telluric, lambda, dataname, fluxsatmedabs

datanamewoext=strmid(file_basename(dataname),0,strlen(dataname)-5)
res=drp_Atmos_Trans(Lambda)
dsttrans=res.output_trans
atmos_wavelen=res.atmos_wavelen
atmos_trans_=res.atmos_trans_


mydevice = !D.NAME
thisLetter = "155B
greekLetter = '!9' + String(thisLetter) + '!X'

openps,gpi_get_directory('GPI_REDUCED_DATA_DIR')+path_sep()+datanamewoext+'telluric.ps', xsize=17, ysize=27 ;, ysize=10, xsize=15
  !P.MULTI = [0, 1, 3, 0, 0] 
plot,lambda,fluxsatmedabs,ytitle='Telluric transmission', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]], charsize=1.5 
oplot, lambda, dsttrans, psym=1
oplot, atmos_wavelen,atmos_trans_,color=fsc_color('red')
legend,['measured trans.','input DST trans.'],psym=[-0,1],/bottom

plot,lambda,fluxsatmedabs-dsttrans,ytitle='Difference of Telluric trans. (meas.-theo)', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]], charsize=1.5 
 plot,lambda,abs(fluxsatmedabs-dsttrans)/dsttrans,ytitle='Abs. relative Diff. of Telluric trans.', xtitle='Wavelength (' + greekLetter + 'm)',$
 xrange=[lambda[0],lambda[n_elements(lambda)-1]], charsize=1.5 
closeps
SET_PLOT, mydevice ;set_plot,'win'

end
