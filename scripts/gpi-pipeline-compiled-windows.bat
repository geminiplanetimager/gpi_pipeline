:: Windows GPI Pipeline Launcher
:: Launches both the GUIs and the Pipeline in a single batch file
::
:: Color is purely cosmetic to attempt to match *nix termnal colors

start cmd /c "color 16 && idl %GPI_DRP_DIR%/executables/gpi_launch_guis.exe"

:: Pause for a second just like the other script
timeout/t 1

start cmd /c "color 1e && idl %GPI_DRP_DIR%/executables/gpi_launch_pipeline.exe"