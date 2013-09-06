
.. _sw-credits:

Credits for the GPI Pipeline Software Development
#############################################################

.. note::
        This listing of credits is incomplete.  Suggestions and improvements welcome. Consult the
        svn repository history or the :ref:`release-notes` for the full details of who did what when.

The GPI Data Analysis Team
----------------------------

Pipeline architecture design, initial algorithms development, core structure, GUI frameworks, and many primitives by **Jerome Maire** and **Marshall Perrin**.  

**Patrick Ingraham** developed and improved many of the primitives, led major aspects of IFS calibration and testing, and extensively contributed to this documentation.
**Dmitry Savransky** made major contributions to GPItv and several pipeline primitives. 
**Christian Marois** contributed to improving SDI algorithms and contrast measurement code. 
**Max Millar-Blanchaer** improved the polarization mode primitives, and with **Sloane Wiktorowicz** calibrated the instrumental polarization.
**Jean-Baptiste "JB" Ruffio** vanquished many bugs, greatly enhanced the destriping and microphonics removal primitives, and wrote the "Quick Start" section of the documentation.
**Naru Sarakuni** juggled data taking and data analysis in support of instrument and pipeline testing.
**Quinn Konopacky** developed the distortion correction primitive.
**Schuyler Wolff** evaluated several aspects of instrument calibrations, tested new methods of wavelength calibration, and contributed significantly to this documentation.
**Alexandra Greenbaum** is leading development of nonredundant aperture masking interferometry algorithms applied to GPI, and also contributed to this documentation.
**Jeff Chilcote** provided guidance on detector operations and calibrations. 
**Steven Beckwith** analyzed detector testing data to assess optimal readout modes. 
**Tyler Barker** implemented the KLIP algorithm, under guidance from Dmitry.
**Franck Marchis** oversees the computer infrastructure at the SETI Institute hosting software repositories and documentation.


**Rene Doyon** was PI of the DRP subsystem for the GPI project, and provided top-level guidance in overall pipeline design. 
**James Graham** developed the core algorithm concepts for the polarization reduction, which were subsequently implemented by Marshall and enhanced by Max. 
**Bruce Macintosh** maintained overall coherence of the GPI project wavefront. 

From Gemini, **Stephen Goodsell** kept the show on track. **Carlos Quiroz** and **Fredrik Rantakyro** supported 
the Gemini Data System, including establishment of interfaces and extensive implementation and testing.
**Kathleen Labrie** provided valuable input from Gemini's perspective during software reviews. 



Other Acknowledgements
------------------------


The GPI pipeline software architecture was inspired by, and portions of the backbone
code re-used from, **the Keck OSIRIS pipeline**.  The OSIRIS pipeline was developed
by James Larkin, Shelley Wright, Jason Weiss, Mike McElwain, Marshall Perrin,
Christof Iserlohe, Alfred Krabbe, Tom Gasaway, and Tommer Wizanski. 


The Recipe Editor (aka ``DRFGUI``) was inspired by the OSIRIS ODRFGUI, orginally written in Java by Jason Weiss. Jerome Maire reimplemented it in a modified form in IDL, with assistance from Marshall Perrin.

gpitv is based on `atv by Aaron Barth et al.
<http://www.physics.uci.edu/~barth/atv/>`_   The Header Viewer dialog in gpitv
is taken from the `OSIRIS Quicklook tool
<http://www2.keck.hawaii.edu/inst/osiris/tools/>`_ ``ql2``, itself derived from
the NIRC2/NIRspec quicklook. The "Browse Files" dialog is based upon code
derived from David Fanning's tool `selectimage.pro
<http://www.idlcoyote.com/programs/catalyst/source/applications/selectimage.pro>`_. The GPI data pipeline is
built upon an extensive foundation of open source software from the astronomical community, including 
but not limited to the Goddard IDL Astronomy Pipeline, the JHUAPL library, Craig Markwardt's MPFIT library, 
Liam Gumley's IMDISP.PRO, and many other individual tools.

 
