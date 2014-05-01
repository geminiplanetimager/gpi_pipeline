Appendix: Improving window appearance via xdefaults
========================================================

.. note::
   This page is about an entirely **optional** and **purely cosmetic** tweak to the pipeline. Feel free to ignore this page entirely. It only applies to Macs and Linux computers.

    .. image:: icon_mac2.png

    .. image:: icon_linux2.png
 


The graphics windows produced by IDL are pretty basic and dated by modern computing standards. Particularly on Macs and Linux computers running X11, GUI windows are entirely
gray on gray. This is kind of boring, and bad from a user interface design standpoint, but we're mostly stuck with it.  IDL does not provide any real ability for programs to control their appearance for instance by adjusting fonts or colors. It just can't be done from inside IDL code!

However, it is possible to slightly tweak the appearance of IDL graphics windows using an ".Xdefaults" file in your home directory, and get slightly improvements to appearance
and legibility.

.. image:: windows_idldefaults.png
        :width: 828px
        :scale: 50 %
        :align: center 

Above: Default appearance. Click for larger.

.. image:: windows_xdefaults.png
        :width: 827 px
        :scale: 50 %
        :align: center 

Above: Slightly improved appearance. Click for larger.
 

If you would like this, please create a file ``.Xdefaults`` in your home directory, and paste the following text into it::


    !---- Customization of Xdefaults values for GPI widgets
    !  Purely cosmetic, no functional changes at all!
    !  Feel free to tweak and adjust as desired.
    !  developed by Marshall Perrin
    !
    !  Copy or append this file to your ~/.Xdefaults to install


    !-- Launcher and status console --
    Idl*GPI_DRP*fontList: *helvetica-bold-r-*--11*
    Idl*GPI_DRP*Table*fontList: *helvetica-medium-r-*--10*
    Idl*GPI_DRP*XmPushButton*background: lightblue
    Idl*GPI_DRP*red_button*background: pink
    Idl*GPI_DRP*Status*red_button*background: pink
    !Idl*GPI_DRP*background: #E9E9F5


    !--- Data Parser ---
    Idl*GPI_DRP_Parser*XmCascadeButton*background: lightblue
    Idl*GPI_DRP_Parser*XmText*background: #F7F7F0
    Idl*GPI_DRP_Parser*XmPushButton*background: #CBE0DF
    Idl*GPI_DRP_Parser*red_button*background: pink
    !Idl*GPI_DRP_Parser*fontList:  *helvetica-bold-r-*--11*
    !Idl*GPI_DRP_Parser*background: #F1E9C8

    !--- Recipe Editor ---
    Idl*GPI_DRP_RecipeEditor*XmText*background: #F7F7F0
    Idl*GPI_DRP_RecipeEditor*XmPushButton*background: #CBE0DF
    Idl*GPI_DRP_RecipeEditor*red_button*background: pink
    !Idl*GPI_DRP_RecipeEditor*fontList:  *helvetica-bold-r-*--11*
    !Idl*GPI_DRP_RecipeEditor*background: #F1E9C8





