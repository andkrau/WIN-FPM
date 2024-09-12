@echo off
call :READINI basePort
call :READINI poolSize
call :READINI phpDir
call :READINI fcgiChildren
call :READINI listenHost
call :READINI watchdogFrequency
call :READINI phpOptions

:START
if not exist "%phpDir%/php-cgi.exe" goto NOPHP
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
for /l %%a in (%basePort%,1,%maxPort%) do echo Starting listener on port %%a && start /b "" "%phpDir%/php-cgi.exe" -b %listenHost%:%%a
echo %totalProcesses% total PHP processes started
echo PHP FastCGI pool ready

:WATCHDOG
for /f "tokens=1,*" %%a in ('tasklist ^| find /I /C "php-cgi.exe"') do set running=%%a
if %running% NEQ %totalProcesses% goto RESTART
timeout /t %watchdogFrequency% /nobreak>nul
goto WATCHDOG

:RESTART
set/a exited=%totalProcesses% - %running%
echo %exited% of %totalProcesses% PHP processes exited abnormally. Restarting PHP!
goto START

:READINI
set found=""
for /f "tokens=1,* delims==" %%a in ('findstr /B /C:"%~1=" "config.ini"') do set %%a=%%b&& set found=%%b
if "%found%" NEQ """" goto :EOF
echo %~1 not found in config.ini!
pause
exit

:NOPHP
echo php-cgi.exe not found in %phpDir%
pause
exit