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
              ;'Copyright _,_ by the University of Montreal ' + $
              ; '(UdeM), Canada', $
              '', $
              '--------- Development: ---------', $
              '', $
              '  Marshall Perrin   (mperrin@stsci.edu)', $
              '  Jerome Maire      (maire@utoronto.ca)', $
			  '  Patrick Ingraham  (patricki@stanford.edu)', $
			  '  Dmitry Savransky  (savransky1@llnl.gov), ', $ 
			  '  Rene Doyon        (doyon@astro.umontreal.ca),', $ 
			  '', $
			  '  with contributions from: ',$
			  '    Jeff Chilcote, Zack Draper, Michael Fitzgerald,', $
			  '    Alex Greenbaum, Quinn Konopacky, Franck Marchis,', $
			  '    Christian Marois, Max Millar-Blanchaer, Laurent Pueyo, ', $
			  '    Jean-Baptiste Ruffio, Naru Sadakuni, Schuyler Wolff',$
			  '    Sloane Wiktorowicz',$
              '', $
              '-------- Acknowledgements: --------', $
              '', $
              '  Bruce Macintosh, Stephen Goodsell, Kathleen Labrie,',$
		  	  '    and all other Gemini and GPI team members', $
              '    who have helped to improve the GPI DRP', $
              '  ', $
			  '  Some code derived from OSIRIS pipeline by:', $
			  '    James Larkin, Michael McElwain', $
			  '    Jason Weiss, Shelley Wright', $
			  '    & Marshall Perrin', $
              ' ', $
			  '  GPItv display tool derived from ATV by', $
              '    Aaron Barth et al.', $
              ' ', $
              '------------------------------', $
              ' ', $
              'The project web site is:         http://planetimager.org/', $
			  '', $
			  'See pipeline issue tracker at:   http://rm.planetimage.org', $
			  '                                 (contact Perrin for an account) ', $
              '', $
              ;'When using this code, please cite the following paper:', $
              ;'  Maire J., Perrin M. D., et al SPIE 2010' + $
              '']

return, tmpstr
end
