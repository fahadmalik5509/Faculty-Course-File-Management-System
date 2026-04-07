@echo off
setlocal

set "LARAGON_ROOT=C:\laragon"
set "DB_USER=root"
set "DB_PASSWORD="
set "SKIP_SEED=0"

:parse_args
if "%~1"=="" goto args_done
if /I "%~1"=="--skip-seed" (
  set "SKIP_SEED=1"
  shift
  goto parse_args
)
if /I "%~1"=="--db-password" (
  if "%~2"=="" (
    echo Missing value for --db-password
    exit /b 1
  )
  set "DB_PASSWORD=%~2"
  shift
  shift
  goto parse_args
)
if /I "%~1"=="--laragon-root" (
  if "%~2"=="" (
    echo Missing value for --laragon-root
    exit /b 1
  )
  set "LARAGON_ROOT=%~2"
  shift
  shift
  goto parse_args
)
echo Unknown option: %~1
echo Supported options: --skip-seed --db-password "value" --laragon-root "path"
exit /b 1

:args_done
set "PROJECT_ROOT=%~dp0"
if "%PROJECT_ROOT:~-1%"=="\" set "PROJECT_ROOT=%PROJECT_ROOT:~0,-1%"
set "SCHEMA_FILE=%PROJECT_ROOT%\backend\db\schema.sql"
set "SEED_FILE=%PROJECT_ROOT%\backend\db\seed.sql"
set "FINAL_URL="
set "WEB_PORT="

if not exist "%SCHEMA_FILE%" (
  echo Missing schema file: %SCHEMA_FILE%
  exit /b 1
)

if "%SKIP_SEED%"=="0" if not exist "%SEED_FILE%" (
  echo Missing seed file: %SEED_FILE%
  exit /b 1
)

set "MYSQL_EXE="
set "MYSQLD_EXE="
set "PHP_EXE="

for /f "delims=" %%D in ('dir /b /ad /o-d "%LARAGON_ROOT%\bin\mysql" 2^>nul') do (
  if not defined MYSQL_EXE if exist "%LARAGON_ROOT%\bin\mysql\%%D\bin\mysql.exe" set "MYSQL_EXE=%LARAGON_ROOT%\bin\mysql\%%D\bin\mysql.exe"
  if not defined MYSQLD_EXE if exist "%LARAGON_ROOT%\bin\mysql\%%D\bin\mysqld.exe" set "MYSQLD_EXE=%LARAGON_ROOT%\bin\mysql\%%D\bin\mysqld.exe"
)

for /f "delims=" %%D in ('dir /b /ad /o-d "%LARAGON_ROOT%\bin\php" 2^>nul') do (
  if not defined PHP_EXE if exist "%LARAGON_ROOT%\bin\php\%%D\php.exe" set "PHP_EXE=%LARAGON_ROOT%\bin\php\%%D\php.exe"
)

if not defined MYSQL_EXE (
  echo Could not find mysql.exe under: %LARAGON_ROOT%\bin\mysql
  exit /b 1
)

if not defined MYSQLD_EXE (
  echo Could not find mysqld.exe under: %LARAGON_ROOT%\bin\mysql
  exit /b 1
)

if not defined PHP_EXE (
  echo Could not find php.exe under: %LARAGON_ROOT%\bin\php
  exit /b 1
)

echo [1/5] Ensuring MySQL server is running...
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -WarningAction SilentlyContinue -InformationLevel Quiet) { exit 0 } else { exit 1 }"
if errorlevel 1 start "" /min "%MYSQLD_EXE%"

echo [2/5] Waiting for MySQL on 127.0.0.1:3306...
set /a _tries=0
:wait_mysql
powershell -NoProfile -ExecutionPolicy Bypass -Command "if (Test-NetConnection -ComputerName 127.0.0.1 -Port 3306 -WarningAction SilentlyContinue -InformationLevel Quiet) { exit 0 } else { exit 1 }"
if not errorlevel 1 goto mysql_ready
set /a _tries+=1
if %_tries% GEQ 40 (
  echo MySQL is not reachable on port 3306.
  exit /b 1
)
timeout /t 1 /nobreak >nul
goto wait_mysql

:mysql_ready
set "AUTH_ARGS=--host=127.0.0.1 --port=3306 --user=%DB_USER% --default-character-set=utf8mb4"
if not "%DB_PASSWORD%"=="" set "AUTH_ARGS=%AUTH_ARGS% --password=%DB_PASSWORD%"

echo [3/5] Importing schema.sql...
type "%SCHEMA_FILE%" | "%MYSQL_EXE%" %AUTH_ARGS%
if errorlevel 1 (
  echo schema.sql import failed.
  exit /b 1
)

if "%SKIP_SEED%"=="1" (
  echo [4/5] Skipping seed import using --skip-seed.
) else (
  echo [4/5] Importing seed.sql...
  type "%SEED_FILE%" | "%MYSQL_EXE%" %AUTH_ARGS%
  if errorlevel 1 (
    echo seed.sql import failed.
    exit /b 1
  )
)

echo [5/5] Opening app URL...
for /f %%P in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$found = $false; foreach ($p in 8080..8090) { $busy = Test-NetConnection -ComputerName 127.0.0.1 -Port $p -WarningAction SilentlyContinue -InformationLevel Quiet; if (-not $busy) { Write-Output $p; $found = $true; break } }; if (-not $found) { exit 1 }"') do set "WEB_PORT=%%P"

if not defined WEB_PORT (
  echo No available local web port found between 8080 and 8090.
  exit /b 1
)

start "" /min "%PHP_EXE%" -S 127.0.0.1:%WEB_PORT% -t "%PROJECT_ROOT%"
set "FINAL_URL=http://127.0.0.1:%WEB_PORT%/"

start "" "%FINAL_URL%"

if errorlevel 1 (
  echo.
  echo Setup failed. See errors above.
  pause
  exit /b 1
)

echo.
echo Setup complete.
echo URL: %FINAL_URL%
endlocal
