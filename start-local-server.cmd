@echo off
cd /d "%~dp0"

set "BUILD_ARG="
if /i "%~1"=="-Build" set "BUILD_ARG=-Build"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-ExecutionPolicy -Scope Process Bypass; . '%~dp0start-local-server.ps1' %BUILD_ARG%"
if errorlevel 1 exit /b %errorlevel%

set AWS_ENDPOINT_URL=http://localhost:4566
set AWS_DEFAULT_REGION=us-east-1
set AWS_ACCESS_KEY_ID=test
set AWS_SECRET_ACCESS_KEY=test
