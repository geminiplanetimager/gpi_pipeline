function persistence_model,im,time,P

N=P[*,*,0] ; normalization
x0=P[*,*,1] ; midpoint of region where persistence is rapidly rising
dx=P[*,*,2] ; width of region where persistence is rapidly rising
alpha=P[*,*,3] ;power law index of slow increase at high sat levels
gamma=P[*,*,4] ; power slope for decay with time
;Persis=N*(1/(exp((x-x0)/dx))+1)*( (x/x0)^alpha ) * (t/1000)^(-gamma)
; now in log space
;log_persis=alog10(N)+alog10( 1/(exp((x-x0)/dx)+1)) $
;           + alpha*alog10( x/x0 ) - gamma*alog10(t/1000)
log_persis=alog10(N)-alog10( exp((im-x0)/dx)+1d0) $
           + alpha*( alog10(im)-alog10(x0) ) - gamma*(alog10(time)-3d0)

RETURN,10d0^(log_persis)
END
