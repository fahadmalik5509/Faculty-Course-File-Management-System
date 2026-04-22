@echo off
setlocal enabledelayedexpansion
title Faculty Course File Management System — Launcher
color 0A

echo.
echo  ============================================================
echo   Faculty Course File Management System - Local Launcher
echo  ============================================================
echo.

:: ================================================================
::  CONFIGURATION  (edit these if your setup differs)
:: ================================================================
set "LARAGON_ROOT=C:\laragon"
set "DB_USER=root"
set "DB_PASSWORD="
set "SKIP_SEED=0"

:: ================================================================
::  ARG PARSING
:: ================================================================
:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--skip-seed"    ( set "SKIP_SEED=1"        & shift & goto parse_args )
if /I "%~1"=="--db-password"  ( set "DB_PASSWORD=%~2"     & shift & shift & goto parse_args )
if /I "%~1"=="--laragon-root" ( set "LARAGON_ROOT=%~2"    & shift & shift & goto parse_args )
echo [WARN] Unknown option: %~1 - ignored
shift & goto parse_args
:args_done

:: ================================================================
::  PATHS
:: ================================================================
set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"

set "SCHEMA_FILE=%PROJECT_ROOT%\backend\db\schema.sql"
set "SEED_FILE=%PROJECT_ROOT%\backend\db\seed.sql"

if not exist "%SCHEMA_FILE%" call :fail "Cannot find backend\db\schema.sql - is run-local.bat in the project root?"
if "%SKIP_SEED%"=="0" if not exist "%SEED_FILE%" call :fail "Cannot find backend\db\seed.sql"

:: ================================================================
::  FIND LARAGON BINARIES
:: ================================================================
echo [1/5] Locating Laragon binaries...

if not exist "%LARAGON_ROOT%" (
  call :fail "Laragon not found at %LARAGON_ROOT%"
)

set "MYSQL_EXE="
set "MYSQLD_EXE="
set "PHP_EXE="

for /f "delims=" %%D in ('dir /b /ad /o-d "%LARAGON_ROOT%\bin\mysql" 2^>nul') do (
  if not defined MYSQL_EXE  if exist "%LARAGON_ROOT%\bin\mysql\%%D\bin\mysql.exe"  set "MYSQL_EXE=%LARAGON_ROOT%\bin\mysql\%%D\bin\mysql.exe"
  if not defined MYSQLD_EXE if exist "%LARAGON_ROOT%\bin\mysql\%%D\bin\mysqld.exe" set "MYSQLD_EXE=%LARAGON_ROOT%\bin\mysql\%%D\bin\mysqld.exe"
)
for /f "delims=" %%D in ('dir /b /ad /o-d "%LARAGON_ROOT%\bin\php" 2^>nul') do (
  if not defined PHP_EXE if exist "%LARAGON_ROOT%\bin\php\%%D\php.exe" set "PHP_EXE=%LARAGON_ROOT%\bin\php\%%D\php.exe"
)

if not defined MYSQL_EXE  call :fail "mysql.exe not found in %LARAGON_ROOT%\bin\mysql"
if not defined MYSQLD_EXE call :fail "mysqld.exe not found in %LARAGON_ROOT%\bin\mysql"
if not defined PHP_EXE    call :fail "php.exe not found in %LARAGON_ROOT%\bin\php"

echo        mysql : %MYSQL_EXE%
echo        php   : %PHP_EXE%

:: ================================================================
::  AUTH ARGS (reused in every mysql call)
:: ================================================================
set "AUTH_ARGS=--host=127.0.0.1 --port=3306 --user=%DB_USER% --connect-timeout=3"
if not "%DB_PASSWORD%"=="" set "AUTH_ARGS=%AUTH_ARGS% --password=%DB_PASSWORD%"

:: ================================================================
::  START MYSQL  (3-stage: already running / service / direct exe)
:: ================================================================
echo [2/5] Starting MySQL...

:: Stage A: already running?
"%MYSQL_EXE%" %AUTH_ARGS% -e "SELECT 1;" >nul 2>&1
if not errorlevel 1 (
  echo        Already running - skipping start.
  goto mysql_ready
)

:: Stage B: try Windows service (Laragon registers one on install)
echo        Trying Windows service...
for %%S in (mysql MySQL mysql80 mysql57 mariadb MariaDB) do (
  net start %%S >nul 2>&1
  if not errorlevel 1 (
    echo        Service %%S started.
    goto wait_mysql
  )
)

:: Stage C: launch mysqld.exe directly
echo        No service found - launching mysqld.exe directly...
start "" /min "%MYSQLD_EXE%" --console

:: ================================================================
::  WAIT FOR MYSQL  (real ping - no Test-NetConnection false positives)
:: ================================================================
:wait_mysql
echo        Waiting for MySQL to accept connections...
set /a tries=0

:ping_loop
"%MYSQL_EXE%" %AUTH_ARGS% -e "SELECT 1;" >nul 2>&1
if not errorlevel 1 goto mysql_ready

set /a tries+=1
if !tries! GEQ 30 (
  echo.
  echo  [ERROR] MySQL did not respond after 30 seconds.
  echo.
  echo  To fix this, try one of the following:
  echo    1. Open Laragon, click "Start All", wait for green MySQL light,
  echo       then double-click run-local.bat again.
  echo    2. If your MySQL has a password:
  echo         run-local.bat --db-password yourpassword
  echo    3. If Laragon is installed elsewhere:
  echo         run-local.bat --laragon-root D:\laragon
  echo.
  pause
  exit /b 1
)

<nul set /p=.
timeout /t 1 >nul
goto ping_loop

:mysql_ready
echo.
echo        MySQL is ready.

:: ================================================================
::  IMPORT SCHEMA
:: ================================================================
echo [3/5] Importing schema...
type "%SCHEMA_FILE%" | "%MYSQL_EXE%" %AUTH_ARGS%
if errorlevel 1 call :fail "Schema import failed. If MySQL has a password, run: run-local.bat --db-password yourpassword"
echo        Done.

:: ================================================================
::  IMPORT SEED
:: ================================================================
if "%SKIP_SEED%"=="0" (
  echo [4/5] Importing seed data...
  type "%SEED_FILE%" | "%MYSQL_EXE%" %AUTH_ARGS%
  if errorlevel 1 call :fail "Seed import failed."
  echo        Done.
) else (
  echo [4/5] Seed skipped.
)

:: ================================================================
::  FIND FREE PORT  (fast netstat - no slow PowerShell)
:: ================================================================
echo [5/5] Starting PHP server...

set "WEB_PORT="
for %%P in (8080 8081 8082 8083 8084 8085 8086 8087 8088 8089 8090) do (
  if not defined WEB_PORT (
    netstat -an 2>nul | find ":%%P " >nul 2>&1
    if errorlevel 1 set "WEB_PORT=%%P"
  )
)

if not defined WEB_PORT call :fail "No free port found between 8080-8090. Close other servers and retry."

set "APP_URL=http://127.0.0.1:%WEB_PORT%"
start "" "%PHP_EXE%" -S 127.0.0.1:%WEB_PORT% -t "%PROJECT_ROOT%"

timeout /t 2 >nul
start "" "%APP_URL%"

:: ================================================================
::  DONE
:: ================================================================
echo        PHP server started on port %WEB_PORT%.
echo.
echo  ============================================================
echo   App is running!
echo.
echo   Open in browser : %APP_URL%
echo.
echo   Login accounts:
echo     Admin   : admin@fms.com   / 12345678
echo     HOD     : hod@fms.com     / 12345678
echo     Teacher : teacher@fms.com / 12345678
echo.
echo   Keep this window open while using the app.
echo   Close it to stop the PHP server.
echo  ============================================================
echo.
pause
exit /b 0

:: ================================================================
::  HELPERS
:: ================================================================
:fail
echo.
echo  [ERROR] %~1
echo.
pause
exit /b 1
