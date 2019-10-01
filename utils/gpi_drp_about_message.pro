;+
; NAME: gpi_drp_about_message
; DESCRIPTION: Display "About the GPI Data Reduction Pipeline" message
;
;
;
;-


function gpi_drp_about_message

    ver=(gpi_pipeline_version())
    tmpstr=['GPI Data Reduction Pipeline Version: '+ver, $
              '', $
              'Copyright 2008-2016, by the GPI Team & AURA', $
			  'Released under a BSD 3-clause license', $
              '', $
              'See http://adsabs.harvard.edu/abs/2014SPIE.9147E..3JP ', $
              '', $
              '--------- Development: ---------', $
              '', $
              '    Marshall Perrin, Jerome Maire, Patrick Ingraham, ', $
			  '    Kate Follette, Dmitry Savransky, Rene Doyon,  ', $ 
			  '', $  
			  '    Pauline Arriaga, Vanessa Bailey, Sebastian Bruzzone, Jeff Chilcote, ', $
			  '    Rob De Rosa, Zack Draper, Michael Fitzgerald, Alex Greenbaum, ', $
			  '    Pascale Hibon, Li-Wei Hung, Quinn Konopacky, Doug Long,', $
			  '    Franck Marchis, Christian Marois, Max Millar-Blanchaer,', $
			  '    Eric Nielsen, Laurent Pueyo, Abhijith Rajan, Fredrik Rantakyro, ',$
			  '    Jean-Baptiste Ruffio, Naru Sadakuni, Jason Wang, ', $
			  '    Kimberly Ward-Duong, Schuyler Wolff, Sloane Wiktorowicz, Joseph Zalesky',$
              '', $
              '-------- Acknowledgements: --------', $
              '', $
              '  Bruce Macintosh, Stephen Goodsell, Kathleen Labrie,',$
		  	  '    and all other Gemini and GPI team members who have ', $
              '    helped to improve the GPI DRP', $
              '  ', $
			  '  Some code derived from OSIRIS pipeline by:', $
			  '    James Larkin, Michael McElwain, Jason Weiss', $
			  '    Shelley Wright, & Marshall Perrin', $
              ' ', $
			  '  GPItv display tool derived from ATV by Aaron Barth et al.', $
              ' ', $
              '------------------------------', $
              ' ', $
              'The pipeline web site is:   http://docs.planetimager.org/pipeline', $
			  '', $
			  'Code and issue tracker at:  http://github.com/geminiplanetimager/gpi_pipeline', $
              '', $
              ;'When using this code, please cite the following paper:', $
              ;'  Maire J., Perrin M. D., et al SPIE 2010' + $
              '']

return, tmpstr
end
