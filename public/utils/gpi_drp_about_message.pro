;+
; NAME: gpi_drp_about_message
; DESCRIPTION: Display "About the GPI Data Reduction Pipeline" message
;
;
;
;-


function gpi_drp_about_message

    ver=strc(gpi_pipeline_version(/svn))
    tmpstr=['GPI Data Reduction Pipeline Version: '+ver, $
              '', $
              'Copyright 2008-2014, by the GPI Team & AURA', $
			  'Released under a BSD 3-clause license', $
              '', $
              '--------- Development: ---------', $
              '', $
              '    Marshall Perrin, Jerome Maire   ', $
			  '    Patrick Ingraham, Dmitry Savransky, Rene Doyon,  ', $ 
			  '', $  
			  '    Jeff Chilcote, Zack Draper, Michael Fitzgerald,', $
			  '    Alex Greenbaum, Quinn Konopacky, Franck Marchis,', $
			  '    Christian Marois, Max Millar-Blanchaer, Laurent Pueyo, ', $
			  '    Jean-Baptiste Ruffio, Naru Sadakuni, Jason Wang, ', $
			  '    Schuyler Wolff, Sloane Wiktorowicz',$
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
              'The pipeline web site is:         http://docs.planetimager.org/pipeline', $
			  '', $
			  'See pipeline issue tracker at:   http://rm.planetimage.org', $
			  '                                 (contact Perrin for an account) ', $
              '', $
              ;'When using this code, please cite the following paper:', $
              ;'  Maire J., Perrin M. D., et al SPIE 2010' + $
              '']

return, tmpstr
end
