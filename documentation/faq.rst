Frequently Asked Questions
=============================

Installation
^^^^^^^^^^^^^^^^^^^^^^^^^

When trying to start the pipeline, I get the error "xterm: Can't execvp idl: No such file or directory"
----------------------------------------------------------------------------------------------------------
This cryptic message means that you are trying to start the gpi-pipeline script without having the idl executable
in your path. Perhaps you have it aliased instead, but that's not detected by the gpi-pipeline starter script. 
You can either (1) change your $PATH to include the directory with idl, (2) put a symlink pointing to idl in some
directory already in your path, or (3) edit your local copy of the gpi-pipeline script to explicitly set the full
path to the idl executable.

