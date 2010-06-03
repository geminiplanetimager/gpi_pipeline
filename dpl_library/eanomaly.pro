function eanomaly,manomaly,eccentricity

;compute the eccentric anomaly given the mean anomaly and eccentricity

;twopi=4.d0*acos(0.d0)
twopi=6.283185307179586232d0
ma=((manomaly mod twopi)+twopi) mod twopi

np=n_elements(ma)
if n_elements(eccentricity) eq np then ecc=double(eccentricity) else ecc=replicate(double(eccentricity[0]),np)

eanomalytab=ma-ecc ;eccentric anomaly, this is the min value it can have
for n=0l,np-1 do begin
    if ecc[n] eq 0. then continue

    ea=eanomalytab[n]
    m=manomaly[n]
    e=ecc[n]
    step=1.d0

    while m+e*sin(ea)-ea gt 1.d-6 do begin
        ;while m+e*sin(ea)-ea ge 0.d0 do ea+=step
        while ea-e*sin(ea) le m do ea+=step
        ea-=step
        step/=10.
    endwhile

    eanomalytab[n]=ea
endfor

return,eanomalytab
end
