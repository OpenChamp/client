@echo off
REM Release helper script for OpenChamp (Windows)
REM Usage: release.bat v1.0.0

setlocal enabledelayedexpansion

if "%1"=="" (
    echo Error: Version not provided
    echo Usage: release.bat v1.0.0
    exit /b 1
)

set VERSION=%1

REM Check if we're in a git repository
git rev-parse --git-dir >nul 2>&1
if errorlevel 1 (
    echo Error: Not in a git repository
    exit /b 1
)

REM Check if the tag already exists
git rev-parse %VERSION% >nul 2>&1
if errorlevel 0 (
    echo Error: Tag %VERSION% already exists
    exit /b 1
)

REM Check if there are uncommitted changes
git diff-index --quiet HEAD -- >nul 2>&1
if errorlevel 1 (
    echo Error: You have uncommitted changes. Please commit or stash them first.
    exit /b 1
)

echo Creating release %VERSION%
echo.

REM Get current branch
for /f %%i in ('git rev-parse --abbrev-ref HEAD') do set CURRENT_BRANCH=%%i
echo Current branch: %CURRENT_BRANCH%

echo.
echo Recent commits (changelog preview):
REM Get previous tag
for /f %%i in ('git describe --tags --abbrev=0 2^>nul') do set PREVIOUS_TAG=%%i

if "!PREVIOUS_TAG!"=="" (
    git log --oneline --no-merges -10
) else (
    git log !PREVIOUS_TAG!..HEAD --oneline --no-merges
)

echo.
echo About to:
echo 1. Create tag: %VERSION%
echo 2. Push tag to origin (triggers CI/CD pipeline)
echo 3. GitHub Actions will build all exports and create a release
echo.

set /p CONTINUE="Continue? (y/n) "
if /i not "%CONTINUE%"=="y" (
    echo Cancelled
    exit /b 1
)

REM Create the tag
echo Creating annotated tag...
git tag -a %VERSION% -m "Release %VERSION%"

REM Push the tag
echo Pushing tag to origin...
git push origin %VERSION%

echo.
echo ✓ Release %VERSION% created and pushed!
echo The CI/CD pipeline is now building all exports.
echo View progress at: https://github.com/openchamp/openchamppc/actions
echo.
echo The release will be automatically published once all builds complete.

endlocal
