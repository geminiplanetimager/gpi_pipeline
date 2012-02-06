; $Id: diagonal_matrix.pro,v 1.3 2003/06/10 18:29:25 riccardi Exp $
;+
;    DIAGONAL_MARIX
;
;  ret = diagonal_matrix(diag)
;
;  Returns a diagonal matrix having the same data type of diag and
;  diag as diagonal elements.
;
; 21 Oct, 2002 Written by A. Riccardi, INAF-Osservatorio Astrofisico di Arcetri (Italy)
;              riccardi@arcetri.astro.it
;
;-
function diagonal_matrix, diagonal

	s = size(diagonal)
	n = s[s[0]+2]
	mat = make_array(TYPE=s[s[0]+1], n, n)
	mat[lindgen(n),lindgen(n)] = diagonal
	return, mat
end
