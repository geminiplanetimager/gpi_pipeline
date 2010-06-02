function changeres, spec, lambint,lambda


         
          ;for bandpass normalization
          bandpassmoy=mean(lambint[1:(size(lambint))[1]-1]-lambint[0:(size(lambint))[1]-2],/DOUBLE)
          bandpassmoy_interp=mean(lambda[1:(size(lambda))[1]-1]-lambda[0:(size(lambda))[1]-2],/DOUBLE)
          norma=bandpassmoy_interp/bandpassmoy
        
          ; interpolate the cube onto a regular grid.
          outspec = norma*INTERPOL( spec, lambint, lambda )
    

return, outspec
end