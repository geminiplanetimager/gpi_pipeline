:: GPI Envrionment Setup Script for Windows
::
:: A batch script to set up environment variables in windows
:: 
:: Requires 'setx' and 'where' which are supported in Windows Vista, 7, 8, 8.1 and higher
::
:: For Windows XP, you will need to replace 'where' with the commented lines and download
:: Support Tools (http://www.microsoft.com/en-us/download/details.aspx?id=18546) to get setx.
:: Alternatively you can set up environment variables manually
::
:: History
:: 12/30/13 - Created (jasonwang)
@echo OFF


:: check to make sure IDL is in path
::
:: windows XP fix (uncomment following two lines, comment the next two)
:: for %i in (idl.exe) do set "idlwhere=%~$PATH:i"
:: if not defined idlwhere (
where /q idl
:idlprompt
if not %ERRORLEVEL%==0 (
	
	set /p "idlBool=idl was not found in your %%PATH%% variable. If you are running this install script for the compiled version of the GPI Pipeline, please ignore this message by entering 'Y'. Otherwise, please install IDL first before installing the GPI pipeline. If IDL is already installed, you will need to add IDL to your PATH or manually start GPI pipeline and GUIs on your own instead of using our launcher. Do you wish to continue installation (not recommended) (Y|N)?"
)
if not %ERRORLEVEL%==0 (
	set "idlBool=%idlBool:~0,1%"
	::call:UpCase idlBool
	if "%idlBool%"=="N" (
		exit 1
	)
	if "%idlBool%"=="Y" (
		echo.
		echo Continuing installation...
		echo.
	) else (
		echo.
		echo Please choose Yes or No
		echo.
		goto:idlprompt
	)
)

::find directory where this file resides, guess where the pipeline and external dirs are
set "scriptDir=%~dp0"
for %%A in ("%~dp0\..") do set "pipelineDir=%%~fA"
for %%A in ("%pipelineDir%\..") do set "baseDir=%%~fA"
set "externDir=%baseDir%\external"
set "dataDir=%baseDir%\data"

echo.
echo We will need to set up some directories. Please provide the correct directory (absolute paths!) for each of the following environment variables. This program will attempt to guess a location that may or may not be right. PLEASE CHECK!
echo.

echo Finding the location of the GPI pipeline directory. This directory should contain folders such as gpitv, primitives, scripts, untils among others.
echo.
call:promptUser pipelineDir

echo.
echo Finding the location of the GPI external libraries directory. This directory should contain gpilib_deps and pipeline_deps.
echo.
call:promptUser externDir

echo.
echo Looking up default directory to set up a GPI Data directory. Please change this to a folder you intend in store GPI data in.
echo.
call:promptUser dataDir

echo.
echo GPI Pipeline directory will be %pipelineDir%
echo GPI External Libraries directory will be %externDir%
echo GPI Data directory will be %dataDir%
echo.

::Set the variables to specify GPI directories
setx GPI_DATA_ROOT %dataDir%
setx GPI_DRP_DIR %pipelineDir%
setx GPI_DRP_QUEUE_DIR %%GPI_DATA_ROOT%%\queue
setx GPI_RAW_DATA_DIR %%GPI_DATA_ROOT%%\Raw
setx GPI_REDUCED_DATA_DIR %%GPI_DATA_ROOT%%\Reduced

echo "Setting up folders in your GPI Data Directory"
echo.
if not exist %dataDir% (
	echo Making directory: %dataDir%
	md %dataDir%
)
if not exist %dataDir%\queue (
	echo Making directory: %dataDir%\queue
	md %dataDir%\queue
)
if not exist %dataDir%\Reduced (
	echo Making directory: %dataDir%\Reduced
	md %dataDir%\Reduced
)
if not exist %dataDir%/Reduced/calibrations (
	echo Making directory: %dataDir%/Reduced/calibrations
	md %dataDir%/Reduced/calibrations
)
if not exist %dataDir%/Reduced/logs (
	echo Making directory: %dataDir%/Reduced/logs
	md %dataDir%/Reduced/logs
)
if not exist %dataDir%/Reduced/recipes (
	echo Making directory: %dataDir%/Reduced/recipes
	md %dataDir%/Reduced/recipes
)
if not exist %dataDir%\Raw (
	echo Making directory: %dataDir%\Raw
	md %dataDir%\Raw
)

::Configure IDL_PATH
echo.
echo.
echo Configuring IDL path variables..
echo.
if not defined IDL_PATH (
	setx IDL_PATH +%pipelineDir%;+%externDir%;^<IDL_DEFAULT^>
) else (
	:: Search IDL Path and see if it is necessary to add GPI paths to IDL path
	:: IDL_Path may have special characters that Windows doesn't like so we need to
	:: use delayed expansion so the parser doesn't getting confused
	setlocal EnableDelayedExpansion
	::set ""="
	set "newIDLPATH=!IDL_PATH!"
	set newIDLPATH=!newIDLPATH:^<=^^^<!
	set newIDLPATH=!newIDLPATH:^>=^^^>!

	echo !newIDLPATH! | findstr /I /C:"%pipelineDir%" 1>nul
	if not errorlevel 0 (
		:: couldn't find, add to idl path
		setx IDL_PATH +%pipelineDir%;!IDL_PATH!
	)
	echo !newIDLPATH! | findstr /I /C:"%externDir%" 1>nul
	if not errorlevel 0 (
		:: couldn't find, add to idl path
		setx IDL_PATH +%externDir%;!IDL_PATH!
	)
	setlocal DisableDelayedExpansion
)

goto:eof

::::::::::::::::::::::::::::::::::::
:::::: Begin Helper Functions ::::::
::::::::::::::::::::::::::::::::::::

:promptUser
:: Function that takes an variable as an argument and prompts user whether value of variable is correct
:: If not, asks user to change to value of the variable
:restartPrompt
call set /p "userBool=For %1, is %%%1%%% the correct path (Y/N)? "
::pick only the first char to determine yes or no
set "userBool=%userBool:~0,1%"
call:UpCase userBool
if "%userBool%"=="Y" (
	::user says it is fine, return
	goto:eof
)
if "%userBool%"=="N" (
	::user manually sets the variable
	set /p "%~1=Please enter the correct path for %1 (absolute paths please): "
	goto:restartPrompt
) else (
	::invalid command
	echo Please choose Yes or No
	echo.
	goto:restartPrompt
)
goto:eof

:EscapeBrackets
:: Subroutine to convert all <> characeters in variable VALUE to ^< and ^>
:: The argument for this subroutine is the variable NAME.
FOR %%i IN ("<=^<" ">=^>") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF

:UpCase
:: Subroutine to convert a variable VALUE to all UPPER CASE.
:: The argument for this subroutine is the variable NAME.
:: Taken from http://www.robvanderwoude.com/battech_convertcase.php
FOR %%i IN ("a=A" "b=B" "c=C" "d=D" "e=E" "f=F" "g=G" "h=H" "i=I" "j=J" "k=K" "l=L" "m=M" "n=N" "o=O" "p=P" "q=Q" "r=R" "s=S" "t=T" "u=U" "v=V" "w=W" "x=X" "y=Y" "z=Z") DO CALL SET "%1=%%%1:%%~i%%"
GOTO:EOF
