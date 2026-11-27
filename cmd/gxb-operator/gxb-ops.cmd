@echo off
rem Thin launcher: run the installed gxb-operator with the same arguments. The
rem operator root defaults to this folder and can be set with GXB_OPERATOR_ROOT.
setlocal
if not defined GXB_OPERATOR_ROOT set "GXB_OPERATOR_ROOT=%~dp0."
"%~dp0gxb-operator.exe" %*
exit /b %ERRORLEVEL%
