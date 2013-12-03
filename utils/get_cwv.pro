function get_cwv,filter,spectralchannels=spectralchannels
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
;   JM 2012-02 number of spectral channel as keyword
;   08.01.2012 - fixed small rounding error in calculation of lambda
;  2012.11.15 JM - change lambda min/max according to 50% filter
;                  transmission
;  2013.09.20 ds - Returns -1 when band has no match
;-

  compile_opt defint32, strictarr, logical_predicate

  tabband=[['Z'],['Y'],['J'],['H'],['K'],['K1'],['K2']]
  parseband=WHERE(STRCMP( tabband, strcompress(filter,/rem), /FOLD_CASE) EQ 1)
  case parseband of
     -1: return,-1
     0:  CommonWavVect=[0.9444, 1.1448, 37]         ;was [0.95, 1.14, 37]
     1:  CommonWavVect=[0.9444, 1.1448, 37]         ;was [0.95, 1.14, 37]
     2:  CommonWavVect=[1.1108, 1.353, 37]                             ;[1.115, 1.34, 37]        ;[1.12, 1.35, 37] ;
     3: CommonWavVect=[1.4904, 1.8016, 37]     ;was[1.495, 1.7938, 37] according to 50% filter transmission instead of CommonWavVect=[1.5, 1.8, 37]
     4:                        
     5:  CommonWavVect=[1.8818, 2.1994, 37]   ;was [1.9, 2.19, 40]
     6: CommonWavVect=[2.1034, 2.4004, 37]    ;was [2.13, 2.4, 40]
  endcase
  

  if keyword_set(spectralchannels) && (spectralchannels ne -1) then CommonWavVect[2]=spectralchannels
  CommonWavVect = double(CommonWavVect)
  dl = CommonWavVect[1] - CommonWavVect[0]
  dx = dl/CommonWavVect[2]
  lambda = dindgen(CommonWavVect[2])/CommonWavVect[2]*dl + CommonWavVect[0] + dx/2d
  
  return,   {CommonWavVect:CommonWavVect, lambda:lambda} 
end
