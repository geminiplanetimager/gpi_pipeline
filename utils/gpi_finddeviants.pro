pro gpi_finddeviants, cubef3D_box,xsi,ysi,badpixmap,nbdev,xmini,OPERATEUR,ybp,nbdev0,nbdev1,nbdev17,nbdev18,isedge,specpixlength
	compile_opt defint32, strictarr, logical_predicate



 
  lampspec = CONVOL( reform(cubef3D_box[xsi,ysi,*]), OPERATEUR,/center,/edge_zero )

        nbdevtab=replicate(double(nbdev), specpixlength)
        nbdevtab[0]*=nbdev0  & nbdevtab[1]*=nbdev1 & nbdevtab[specpixlength-2]*=nbdev17 & nbdevtab[specpixlength-1]*=nbdev18
  ind=where(abs(reform(cubef3D_box[xsi,ysi,0:specpixlength-1])-lampspec[0:specpixlength-1]) gt nbdevtab*reform(cubef3D_box[xsi,ysi,0:specpixlength-1]),cc)
    

        if (cc ne 0) && (total(cubef3D_box[xsi,ysi,*]) ne 0.) then begin

              for i=0,n_elements(ind)-1 do begin
                xbp=floor(xmini[xsi,ysi]+ind[i]-1-specpixlength)
                      ;if xbp ne 3 && xbp ne 2060 then begin 
                      if xbp gt 3 && xbp lt 2044 then begin 
                       if (ind[i] eq 0) || (ind[i] eq 1) ||(ind[i] eq specpixlength-1) || $ ;cond for edge effect:
                       (( isedge*mean(cubef3D_box[xsi,ysi,ind[i]-4>0:ind[i]]) lt mean(cubef3D_box[xsi,ysi,ind[i]:ind[i]+4<specpixlength-1])) && $
                        ( mean(cubef3D_box[xsi,ysi,ind[i]-4>0:ind[i]]) gt isedge*mean(cubef3D_box[xsi,ysi,ind[i]:ind[i]+4<specpixlength-1]) )) then begin
              
                                  badpixmap[ybp,xbp]=1 


                        endif
                      endif
             endfor
        endif

        
end
