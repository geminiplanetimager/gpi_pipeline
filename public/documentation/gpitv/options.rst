GPItv Options
===============


There are a variety of options for GPItv that can be configured on its Options menu. 
To change the default settings for all newly opened GPItv windows, you can set these options in your
:ref:`pipeline configuration file <config_settings>`.

==================================      =========================================================================================
Option Name                             Behavior
==================================      =========================================================================================
*Retain Current Slice*                  If set, then when a new datacube is opened, it will stay at the same spectral channel. 
                                        (Assuming the datacube has sufficient spectral channels such that this is possible). 
                                        Has no effect on 2D images. 
*Retain Current Stretch*                If set, then when a new datacube is opened, the display scaling will remain unchanged. 
                                        If not set, the default behavior is to autoscale for the new image. 

*Retain Current Zoom*                   If set, then when a new image is opened, it will keep the same zoom and position settings
                                        as the previous image (if possible). If not set, the defaulf behavior is to 
                                        automatically zoom such that the image fits just within the gpitv display window.    
*Auto Handedness*                       If set, then when an image is opened the handedness of its coordinate system is
                                        checked. If it's right-handed (east is clockwise of north), then it will be
                                        flipped left-to-right to become the normal astronomical convention of
                                        left-handed (east is counterclockwise of north). Note that no *rotation* takes
                                        place here, so north will not be aligned up; this is just a matter of getting
                                        the sign convention arranged as desired. This can be done using the 'Rotate
                                        North Up' option on the zoom menu if desired. 
*Suppress Information Messages*         GPItv occasionally produces informational messages, either printed to the screen or 
                                        displayed in dialog boxes. They can be suppressed if desired using htis option.
*Suppress Warning Messages*             In response to an unexpected event, GPItv occasionally produces warning
                                        messages, either printed to the screen or displayed in dialog boxes. They can
                                        be suppressed if desired using htis option.
*Display Full Paths*                    The filename in the window title bar is by default just the base name of the
                                        file itself. Select this to make GPItv display instead the full path including
                                        directory names. 
==================================      =========================================================================================
