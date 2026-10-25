@echo off
setlocal EnableExtensions DisableDelayedExpansion

rem Launches the Flutter web app with config from the backend .env.local.
rem Values are passed as --dart-define and are never echoed.

set "ENV_FILE=C:\src\sidama_way_go_backend\.env.local"
set "EXPECTED_FIREBASE_PROJECT=bekan-automotive-solution"

if not exist "%ENV_FILE%" (
  echo [run_web] ERROR: env file not found: %ENV_FILE%
  exit /b 1
)

set "SB_URL="
set "SB_ANON_KEY="
set "FB_PROJECT_ID="

for /f "usebackq tokens=1,* delims==" %%A in ("%ENV_FILE%") do (
  if /i "%%A"=="NEXT_PUBLIC_SUPABASE_URL" set "SB_URL=%%~B"
  if /i "%%A"=="NEXT_PUBLIC_SUPABASE_ANON_KEY" set "SB_ANON_KEY=%%~B"
  if /i "%%A"=="FIREBASE_PROJECT_ID" set "FB_PROJECT_ID=%%~B"
)

if not defined SB_URL (
  echo [run_web] ERROR: NEXT_PUBLIC_SUPABASE_URL is missing or empty in %ENV_FILE%
  exit /b 1
)
if not defined SB_ANON_KEY (
  echo [run_web] ERROR: NEXT_PUBLIC_SUPABASE_ANON_KEY is missing or empty in %ENV_FILE%
  exit /b 1
)
if not defined FB_PROJECT_ID (
  echo [run_web] ERROR: FIREBASE_PROJECT_ID is missing or empty in %ENV_FILE%
  exit /b 1
)

echo %SB_URL% | findstr /b /c:"https://" >nul
if errorlevel 1 (
  echo [run_web] ERROR: NEXT_PUBLIC_SUPABASE_URL must start with https://
  exit /b 1
)

if /i not "%FB_PROJECT_ID%"=="%EXPECTED_FIREBASE_PROJECT%" (
  echo [run_web] ERROR: FIREBASE_PROJECT_ID is "%FB_PROJECT_ID%" but firebase_options.dart is built for %EXPECTED_FIREBASE_PROJECT%.
  exit /b 1
)

echo [run_web] Loaded config from %ENV_FILE%
echo [run_web]   Supabase URL:     SET
echo [run_web]   Supabase anon key: SET
echo [run_web]   Firebase project: %FB_PROJECT_ID%

if /i "%~1"=="--check" (
  echo [run_web] Config check passed. Flutter was not launched.
  exit /b 0
)

echo [run_web] Starting flutter run -d chrome (MVP_MODE=false)...
flutter run -d chrome "--dart-define=SUPABASE_URL=%SB_URL%" "--dart-define=SUPABASE_ANON_KEY=%SB_ANON_KEY%" "--dart-define=FIREBASE_PROJECT_ID=%FB_PROJECT_ID%" "--dart-define=MVP_MODE=false" %*
set "RUN_EXIT_CODE=%ERRORLEVEL%"

endlocal & exit /b %RUN_EXIT_CODE%
