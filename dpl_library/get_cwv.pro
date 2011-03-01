
;+
; NAME: get_cwv
;  get lambda_min,lambda_max and # spectral channel in final datacube
;
; INPUTS: filter
;
;
; OUTPUTS: CommonWavVect
;   
;
; HISTORY:
;   JM 2009-12


function get_cwv,filter

        tabband=[['Z'],['Y'],['J'],['H'],['K'],['K1'],['K2']]
        parseband=WHERE(STRCMP( tabband, strcompress(filter,/rem), /FOLD_CASE) EQ 1)
        case parseband of
            -1: CommonWavVect=-1
            0:  CommonWavVect=[0.95, 1.18, 37];[0.95, 1.14, 37]
            1:  CommonWavVect=[0.95, 1.18, 37];[0.95, 1.14, 37]
            2:  CommonWavVect=[1.15, 1.33, 37] ;[1.12, 1.35, 37]
            3: CommonWavVect=[1.5, 1.8, 37]
            4:  ;CommonWavVect=[1.5, 1.8, 37]
            5:  CommonWavVect=[1.9, 2.19, 40]
            6: CommonWavVect=[2.13, 2.4, 40]
        endcase
        lambda=dblarr(CommonWavVect[2])
        for i=0,CommonWavVect[2]-1 do lambda[i]=CommonWavVect[0]+(CommonWavVect[1]-CommonWavVect[0])/(2.*CommonWavVect[2])+double(i)*(CommonWavVect[1]-CommonWavVect[0])/(CommonWavVect[2])
        
     return,   {CommonWavVect:CommonWavVect,lambda:lambda} 
end