function about_message

    ver=strc(gpi_pipeline_version())
    tmpstr=['GPI DRF-GUI Revision: '+ver+'  - GPI 3d data-reduction package', $
              '', $
              'Copyright _,_ by the University of Montreal ' + $
               '(UdeM), Canada', $
              '', $
              'Programming (report bugs to):', $
              '  Jerome Maire (UdeM, maire@astro.umontreal.ca)', $
              '  Marshall Perrin (UCLA)', $
              '', $
              'Documentation:', $
              '  Marshall Perrin (UCLA)', $
              '  Jerome Maire (UdeM)', $
              '', $
              'This software has been tested by:', $
              '  Jeff Chilcote, Quinn Konopacky ', $
              '', $
              'Acknowledgements:', $
              '  ', $
              '    which have helped improve GPI DRF-GUI', $
              '  ', $
              ' ', $
              '', $
              'The project web site is:', $
              '  ', $
              '', $
              'When using this code, please cite the following paper:', $
              '  Maire J., Perrin M. D., et al SPIE 2010' + $
              '', $
              '']

return, tmpstr
end