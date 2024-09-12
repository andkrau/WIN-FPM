@echo off
call :readINI basePort
call :readINI poolSize
call :readINI phpDir
call :readINI fcgiChildren
call :readINI listenHost
call :readINI phpOptions

if not exist "%phpDir%/php-cgi.exe" goto noPHP
echo Killing all other running PHP processes
wmic process where name="php-cgi.exe" delete>nul
echo Disabling PHP Max Requests Limit
set PHP_FCGI_MAX_REQUESTS=0
echo Setting Number of PHP FastCGI Child Processes
set PHP_FCGI_CHILDREN=%fcgiChildren%
set totalProcesses=%poolSize%
set /a totalChildren=%fcgiChildren% * %poolSize%
if %fcgiChildren% GTR 0 set /a totalProcesses=%totalChildren% + %poolSize%
set /a maxPort=%basePort% + %poolSize% - 1
echo Creating pool of %poolSize% PHP parent processes with %totalChildren% total child processes
FOR /L %%a IN (%basePort%,1,%maxPort%) DO echo Starting listener on port %%a && start /b "" "%phpDir%/php-cgi.exe" -b %listenHost%:%%a
echo %totalProcesses% total PHP processes started
echo PHP FastCGI pool ready
pause>nul
exit

:readINI
SET FOUND=""
for /f "tokens=1,* delims==" %%a in ('findstr /B /C:"%~1=" "config.ini"') do set %%a=%%b&& set FOUND=%%b
IF "%FOUND%" NEQ "" GOTO :EOF
ECHO %~1 not found in config.ini!
pause
exit

:noPHP
echo php-cgi.exe not found in %phpDir%
pause
exit