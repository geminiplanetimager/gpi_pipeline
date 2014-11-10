;JM created

function interpolatej,data,x,y,z

szdata=size(data)
if z lt szdata[3]-1 then begin 
neighboor=[data[x>0,y>0,(z-1)>0], data[x>0,y>0,(z+1)>0], $
            data[(x-1)>0,y>0,z>0],  data[(x+1)>0,y>0,z>0], $
             data[x>0,(y-1)>0,z>0],   data[x>0,(y+1)>0,z>0] ]
endif else begin
neighboor=[data[x>0,y>0,(z-1)>0],  $
            data[(x-1)>0,y>0,z>0],  data[(x+1)>0,y>0,z>0], $
             data[x>0,(y-1)>0,z>0],   data[x>0,(y+1)>0,z>0] ]
endelse             
val=mean(neighboor,/Nan)

return,val
end