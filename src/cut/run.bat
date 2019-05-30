@echo off
copy /y /a %cd%\..\src\modules\definitions.cmd + /a %cd%\test.cmd + /a %cd%\..\src\modules\params.cmd + /a %cd%\..\src\modules\utils.cmd + /a %cd%\..\src\modules\echo.cmd + /a %cd%\..\src\modules\strings.cmd %cd%\test_.cmd /a
rem call %cd%\test_.cmd %*
rem call %cd%\test_.cmd -lc:ru --help
rem call %cd%\test_.cmd -lc:ru -ss:params.cmd -so:false
rem call %cd%\test_.cmd -lc:ru -ss:registry.cmd
rem call %cd%\test_.cmd -lc:ru -ss:strings.cmd
rem call %cd%\test_.cmd -lc:ru -ss:utils.cmd
rem -so:false
call %cd%\test_.cmd -lc:ru -ss:bis.cmd -ts:test_wb_get_pkg_dirs.cmd -so:false
rem call %cd%\test_.cmd -lc:ru -ss:bis.cmd -ts:test_wb_proc_trim.cmd
rem call %cd%\test_.cmd -lc:ru -ss:bis.cmd -ts:test_wb_get_mod_install_dirs.cmd
del /q %cd%\test_.cmd
