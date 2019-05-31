@Echo Off
rem {Copyright}
rem {License}
rem Каркас тестирования сценариев и приложений интерфейса командной строки

setlocal EnableExtensions EnableDelayedExpansion
cls
rem УСТАНОВКА И ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ:
rem текущий каталог
set CUR_DIR=%~dp0
rem каталог тестируемых (исходных) сценариев
set DEF_SRC_PATH=..%DIR_SEP%src
rem каталог тестовых сценариев
set DEF_TST_PATH=%CUR_DIR%
rem Предопределённые скрипты:
rem настройка и удаление фикстуры (тестового окружения)
set SETUP_FILE=setup_before.cmd
set TEARDOWN_FILE=teardown_after.cmd
rem порядок склеивания сценариев
set ORD_PREPEND=PREPEND
set ORD_APPEND=APPEND
rem Префиксы скриптов:
rem тестового скрипта
set TST_PREFIX=test_
rem тестового скрипта "белый ящик"
set WB_PREFIX=test_wb_
rem комбинированного тестового скрипта
set CMB_PREFIX=$
rem Символы результатов тестов мантры "red/green/refactor":
set TR_OK=.
set TR_FAILED=F
set TR_SKIPPED=S
set TR_ERROR=E
rem Результаты тестов:
set RESULT_OK=0
set RESULT_SKIPPED=1
set RESULT_ERROR=2
set RESULT_FAILED=10

rem наименование сценария и его заголовок
set g_script_name=%~nx0
set g_script_name=%g_script_name:cmd-win1251.cmd=exe%
set g_script_header=Victory CUT [Command line interface Unit Testing] for Windows 7/10 {Current_Version}. {Copyright} {Current_Date}

rem РАЗБОР ПАРАМЕТРОВ ЗАПУСКА:
set test_param_defs="-lc,locale;-sp,p_src_path,%DEF_SRC_PATH%;-tp,p_tst_path,%DEF_TST_PATH%;-ss,p_src_script;-ts,p_test_script;-gl,p_green_line,%VL_FALSE%;-af,p_abort_on_fail,%VL_FALSE%;-so,p_supress_output,%VL_TRUE%"
call :parse_params %~0 %test_param_defs% %*
rem ошибка разбора определений параметров
if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem вывод справки
if ERRORLEVEL 1 set p_key_help=%VL_TRUE%
rem call :print_params %~0
rem Определяем локаль системы
if not defined locale call :get_locale 1>nul 2>&1

rem файлы ресурсов
set g_res_file=%CUR_DIR%strings_%locale%.txt
set menus_file=%CUR_DIR%menus_%locale%.txt
set help_file=%CUR_DIR%helps_%locale%.txt

rem настройка пути к утилите вывода
call :chgcolor_setup "%CUR_DIR%"
rem выводим помощь
if defined p_key_help call :test_help & endlocal & exit /b 0

rem для всех сценариев устанавливаем режим выполнения - тестирование
set EXEC_MODE=%EM_TST%
rem переходим в текущий каталог сценария тестирования
for /f %%i in ("%p_tst_path%") do set p_tst_path=%%~dpnxi
pushd "%p_tst_path%"
rem cd /d %p_tst_path%

set all_run=0
set all_failed=0
set all_errors=0
set all_skipped=0
set all_succeeded=0

if /i "%p_green_line%" EQU "%VL_FALSE%" (
	call :echo -it:true -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0D -be:1
	call :echo -it:true -rf:"%menus_file%" -ri:MenuHeader -rc:0D
	call :echo -it:true -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0D -ae:1
)
set all_tests_start_time=%time%
rem получаем все каталоги тестов (последний каталог, содержащий скрипты тестов именнуется как тестируемый сценарий)
for /F %%a in ('dir /a:d /b /s 2^>nul') do (
	set l_test_dir_ptrn=%%a
	rem echo "!l_test_dir_ptrn!"
	rem формируем путь к тестируемому сценарию
	set l_src_dir=%p_src_path%%DIR_SEP%!l_test_dir_ptrn:%p_tst_path%=!
	echo "!l_src_dir!"
	for /f %%i in ("!l_src_dir!") do set l_src_dir=%%~dpi
	set l_src_script_name=%%~na
	set l_src_script_path=!l_src_dir!!l_src_script_name!.cmd
	rem если тестируемый сценарий существует
	if not exist "!l_src_script_path!" set l_src_script_path=!l_src_dir!!l_src_script_name!.bat
	if exist "!l_src_script_path!" (
		rem если не указан исходный сценарий
		if "%p_src_script%" EQU "" (
			call :execute_tests "!l_test_dir_ptrn!" "!l_src_script_path!" "!l_src_dir!" "!l_src_script_name!"
		) else (
			rem если указан исходный сценарий, то тестируем только его
			set $src_script=!l_src_script_path:%p_src_script%=!
			if /i "!$src_script!" NEQ "!l_src_script_path!" (
				call :execute_tests "!l_test_dir_ptrn!" "!l_src_script_path!" "!l_src_dir!" "!l_src_script_name!"
			)
		)
		rem если запрошено прерывание тестирования, то прерываем его
		if ERRORLEVEL 1 goto :end_tests
	)
)
:end_tests
popd
if /i "%p_green_line%" EQU "%VL_TRUE%" echo.
set all_tests_end_time=%time%
set /a "failed_cnt=all_failed-1"
set /a "errors_cnt=all_errors-1"
set /a "skipped_cnt=all_skipped-1"

if /i "%p_green_line%" EQU "%VL_FALSE%" (
	call :echo -it:true -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0D
	call :echo -it:true -rf:"%menus_file%" -ri:MenuResults -rc:0D
	call :echo -it:true -rf:"%menus_file%" -ri:MenuHeaderSeparator -rc:0D -ae:1
) else (
        if %failed_cnt% EQU -1 (
		call :echo -it:true -rf:"%menus_file%" -ri:GreenRedLine -rc:AA
	) else (
		call :echo -it:true -rf:"%menus_file%" -ri:GreenRedLine -rc:CC
        )
)
call :echo_broken_scripts %skipped_cnt% BrokenTestsSkipped 0B skippeds
call :echo_broken_scripts %errors_cnt% BrokenTestsError 0E errors
call :echo_broken_scripts %failed_cnt% BrokenTestsFailed 0C faileds

call :echo_test_results 0F %all_run% %all_failed% %all_errors% %all_skipped% "%all_tests_start_time%" "%all_tests_end_time%"
echo.
exit /b 0

rem ---------------------------------------------
rem Выполняет тесты заданного исходного сценария
rem ---------------------------------------------
:execute_tests _test_dir_ptrn _src_script_path _src_dir _src_script_name
set _test_dir_ptrn=%~1
set _src_script_path=%~2
set _src_dir=%~3
set _src_script_name=%~4

set run=0
set failed=0
set errors=0
set skipped=0
set succeeded=0
if /i "%p_green_line%" EQU "%VL_FALSE%" if "%p_test_script%" EQU "" call :echo -it:true -ri:SrcScriptRunning -v1:"%_src_script_path%" -rc:0F

set tests_start_time=%time%
rem формируем пути к сценариям-тестам
rem выполняем предопределённый скрипт установки фикстуры
set l_prepend_str=
set l_append_str=
if exist "%_test_dir_ptrn%%DIR_SEP%%SETUP_FILE%" (
   	for /F "usebackq tokens=1,2 delims==" %%a IN (`%_test_dir_ptrn%%DIR_SEP%%SETUP_FILE% "%_src_script_path%" "%_src_dir%" "%_src_script_name%"`) DO (
		set l_order=%%~a
		set l_script_path=%%~b
		rem echo "!l_order!"="!l_script_path!"
		if exist "!l_script_path!" (
			if /i "!l_order!" EQU "%ORD_PREPEND%" (
				set l_prepend_str=/a "!l_script_path!" + !l_prepend_str!
			) else if /i "!l_order!" EQU "%ORD_APPEND%" (
				set l_append_str=!l_append_str! + /a "!l_script_path!"
			) else if /i "%p_supress_output%" NEQ "%VL_TRUE%" (
				set sf_msg=!l_order!
				if "!l_script_path!" NEQ "" set sf_msg=!sf_msg!=!l_script_path!
				call :echo -it:true -ri:SetupFixtureMsg -v1:"!sf_msg!"
			)
		)
	)
)
rem echo "%l_prepend_str%" "%l_append_str%"
pushd "%_test_dir_ptrn%"
for /F %%c in ('dir *.cmd /b /s /o:n /a-d 2^>nul') do (
	set l_test_path=%%~c
	set l_single_test=%VL_FALSE%
	for /f %%i in ("!l_test_path!") do set l_test_file=%%~nxi
	for /f %%i in ("!l_test_path!") do set l_test_dir=%%~dpi
	rem если тестовый скрипт
	if /i "!l_test_file:~0,5!" EQU "%TST_PREFIX%" (
		rem если не задан конкретый тест, выполняем все
		if "%p_test_script%" EQU "" (
			call :gen_wb_test_path "!l_test_file!" "!l_test_dir!" "!l_test_path!" "%_src_script_path%" "%l_prepend_str%" "%l_append_str%"
			if exist "!wb_test_path!" set l_test_path=!wb_test_path!
			call :run_test "!l_test_path!" "%_src_script_path%" "%_src_dir%" "%_src_script_name%"
			rem если тест запросил прерывание - прерываем
			if ERRORLEVEL 1 popd & exit /b 1
		) else (
			rem иначе - только заданный конкретый тест
			if /i "!l_test_file!" EQU "%p_test_script%" (
				call :gen_wb_test_path "!l_test_file!" "!l_test_dir!" "!l_test_path!" "%_src_script_path%" "%l_prepend_str%" "%l_append_str%"
				if exist "!wb_test_path!" set l_test_path=!wb_test_path!
				call :run_test "!l_test_path!" "%_src_script_path%" "%_src_dir%" "%_src_script_name%"
				set l_single_test=%VL_TRUE%
			)
		)
		rem если тестируем "белый ящик", удаляем комбинированный тест
		if exist "!wb_test_path!" 1>nul del /q "!wb_test_path!"
		rem если выполнен единственный заданный тестовый скрипт, то запрашиваем прерывание тестирования
		if /i "!l_single_test!" EQU "%VL_TRUE%" (
			call :exec_teardown "%_test_dir_ptrn%" "%_src_script_path%" "%_src_dir%" "%_src_script_name%"
			popd & exit /b 1
		)
	)
)
popd
if !run! EQU 0 set /a "skipped+=1" & set /a "all_skipped+=1"
rem выполняем предопределённый скрипт удаления фикстуры
call :exec_teardown "%_test_dir_ptrn%" "%_src_script_path%" "%_src_dir%" "%_src_script_name%"
set tests_end_time=%time%
if /i "%p_green_line%" EQU "%VL_FALSE%" (
	call :echo_test_results 08 !run! !failed! !errors! !skipped! "!tests_start_time!" "!tests_end_time!"
	call :echo -it:true -ri:TestsRunningIn -v1:"%_src_script_path%" -ae:1
)
exit /b 0

rem ---------------------------------------------
rem Выполняет удаление фикстуры (тестового окружения)
rem ---------------------------------------------
:exec_teardown
setlocal
set _test_dir_ptrn=%~1
set _src_script_path=%~2
set _src_dir=%~3
set _src_script_name=%~4

rem выполняем предопределённый скрипт удаления фикстуры
if exist "%_test_dir_ptrn%%DIR_SEP%%TEARDOWN_FILE%" (
	if /i "%p_supress_output%" EQU "%VL_TRUE%" (
		call "%_test_dir_ptrn%%DIR_SEP%%TEARDOWN_FILE%" "%_src_script_path%" "%_src_dir%" "%_src_script_name%" 1>nul 2>&1
	) else (
		call "%_test_dir_ptrn%%DIR_SEP%%TEARDOWN_FILE%" "%_src_script_path%" "%_src_dir%" "%_src_script_name%"
	)
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Генерирует комбинированный сценарий для теста 
rem "белого ящика" и возвращает путь к нему
rem ---------------------------------------------
:gen_wb_test_path _test_file _test_dir _test_path _src_script_path _prepend_str _append_str
setlocal
set _exec_name=%~0
set _test_file=%~1
set _test_dir=%~2
set _test_path=%~3
set _src_script_path=%~4
set _prepend_str=%~5
set _append_str=%~6

rem если тестируем "белый ящик"
if /i "%_test_file:~0,8%" EQU "%WB_PREFIX%" (
	set l_cmb_test_path=!_test_dir!%CMB_PREFIX%!_test_file!
	1>nul copy /y %_prepend_str%/a "%_test_path%" + /a "%_src_script_path%"%_append_str% "!l_cmb_test_path!" /a
	rem pause
	rem exit
)
endlocal & set %_exec_name:~5%=%l_cmb_test_path%
exit /b 0

rem ---------------------------------------------
rem Выполняет тест заданного исходного сценария
rem ---------------------------------------------
:run_test _test_path _src_script_path _src_dir _src_script_name
set _test_path=%~1
set _src_script_path=%~2
set _src_dir=%~3
set _src_script_name=%~4

rem если не мантра "red/green/refactor" формируем вывод
set l_test_path=!_test_path:%CMB_PREFIX%=!
if /i "%p_green_line%" EQU "%VL_FALSE%" call :echo -it:true -ri:TestPath -v1:"%l_test_path%" -ln:false -rs:4
rem запуск теста с замером времени выполнения
rem если задано подавление вывода тестов
if /i "%p_supress_output%" EQU "%VL_TRUE%" (
	set test_start_time=!time!
	call "%_test_path%" "%_src_script_path%" "%_src_dir%" "%_src_script_name%" 1>nul 2>&1
	set test_result_code=!ERRORLEVEL!
	set test_end_time=!time!
) else (
	set test_start_time=!time!
	call "%_test_path%" "%_src_script_path%" "%_src_dir%" "%_src_script_name%"
	set test_result_code=!ERRORLEVEL!
	set test_end_time=!time!
)
rem тест провален
if !test_result_code! GEQ %RESULT_FAILED% (
	set faileds[!all_failed!]#Script=%l_test_path%
	set /a l_test_no=%test_result_code%-%RESULT_FAILED%+1
	set faileds[!all_failed!]#TestCase=!l_test_no!
	set faileds[!all_failed!]#ExitCode=%test_result_code%
	set /a "failed+=1"
	set /a "all_failed+=1"
	rem если не мантра "red/green/refactor" формируем вывод
	if /i "%p_green_line%" EQU "%VL_FALSE%" (
		if "%p_test_script%" EQU "" (
			call :echo -it:true -ri:ResultFailed -rc:0C
		) else (
			call :echo -it:true -ri:ResultFailedFull -v1:!l_test_no! -v2:%test_result_code% -rc:0C
		)
	) else (
		call :echo -it:true -ri:TestResult -v1:%TR_FAILED% -rc:0C -ln:false
	)
	rem если задано прерывание процесса тестирования
	if /i "%p_abort_on_fail%" EQU "%VL_TRUE%" (
		rem если не мантра "red/green/refactor" формируем вывод
		if /i "%p_green_line%" EQU "%VL_FALSE%" call :echo -it:true -ri:TestsAborting -rc:0C -be:1
		exit /b 1
	)
)
rem тест не может быть выполнен из-за логической ошибки
if !test_result_code! EQU %RESULT_ERROR% (
	set errors[!all_errors!]#Script=%l_test_path%
	set /a "errors+=1"
	set /a "all_errors+=1"
	rem если не мантра "red/green/refactor" формируем вывод
	if /i "%p_green_line%" EQU "%VL_FALSE%" (
		call :echo -it:true -ri:ResultError -rc:0E
	) else (
		call :echo -it:true -ri:TestResult -v1:%TR_ERROR% -rc:0E -ln:false
	)
)
rem тест пропущен
if !test_result_code! EQU %RESULT_SKIPPED% (
	set skippeds[!all_skipped!]#Script=%l_test_path%
	set /a "skipped+=1"
	set /a "all_skipped+=1"
	rem если не мантра "red/green/refactor" формируем вывод
	if /i "%p_green_line%" EQU "%VL_FALSE%" (
		call :echo -it:true -ri:ResultSkipped -rc:0B
	) else (
		call :echo -it:true -ri:TestResult -v1:%TR_SKIPPED% -rc:0B -ln:false
	)
)
rem тест пройден
if !test_result_code! EQU %RESULT_OK% (
	set /a "succeeded+=1"
	set /a "all_succeeded+=1"
	rem если не мантра "red/green/refactor" формируем вывод
	if /i "%p_green_line%" EQU "%VL_FALSE%" (
		call :echo -it:true -ri:ResultOk -rc:0A -ln:false
		call :echo_measure_time "!test_start_time!" "!test_end_time!"
		echo.
	) else (
		call :echo -it:true -ri:TestResult -v1:%TR_OK% -rc:0A -ln:false
	)
)
set /a "run+=1"
set /a "all_run+=1"

exit /b 0

rem ---------------------------------------------
rem Выводит результаты тестирования 
rem (в т.ч. замеренное время выполнения тестов)
rem ---------------------------------------------
:echo_test_results _main_color _run_cnt _failed_cnt _errors_cnt _skipped_cnt _start _end
setlocal
set _main_color=%~1
set _run_cnt=%~2
set _failed_cnt=%~3
set _errors_cnt=%~4
set _skipped_cnt=%~5
set _start=%~6
set _end=%~7

rem если мантра "red/green/refactor" прерываем вывод
if /i "%p_green_line%" EQU "%VL_TRUE%" endlocal & exit /b 0

call :echo -it:true -ri:ResultTestsRun -v1:%_run_cnt% -rc:%_main_color% -ln:false
if %_run_cnt% GTR 0 (
	call :echo -it:true -rv:", " -rc:%_main_color% -ln:false
	if %_failed_cnt% GTR 0 (
		call :echo -it:true -ri:ResultTestsFailures -v1:%_failed_cnt% -rc:0C -ln:false
		call :echo -it:true -rv:", " -rc:%_main_color% -ln:false
	)
	if %_errors_cnt% GTR 0 (
		call :echo -it:true -ri:ResultTestsErrors -v1:%_errors_cnt% -rc:0E -ln:false
		call :echo -it:true -rv:", " -rc:%_main_color% -ln:false
	)
	if %_skipped_cnt% GTR 0 (
		call :echo -it:true -ri:ResultTestsSkipped -v1:%_skipped_cnt% -rc:0B -ln:false
		call :echo -it:true -rv:", " -rc:%_main_color% -ln:false
	)
	call :echo_measure_time "%_start%" "%_end%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит замеренное время выполнения тестов
rem ---------------------------------------------
:echo_measure_time _start _end
setlocal
set _start=%~1
set _end=%~2

set options="tokens=1-4 delims=:.,"
for /f %options% %%a in ("%_start%") do set start_h=%%a&set /a start_m=100%%b %% 100&set /a start_s=100%%c %% 100&set /a start_ms=100%%d %% 100
for /f %options% %%a in ("%_end%") do set end_h=%%a&set /a end_m=100%%b %% 100&set /a end_s=100%%c %% 100&set /a end_ms=100%%d %% 100

set /a hours=%end_h%-%start_h%
set /a mins=%end_m%-%start_m%
set /a secs=%end_s%-%start_s%
set /a ms=%end_ms%-%start_ms%
if %ms% lss 0 set /a secs = %secs% - 1 & set /a ms = 100%ms%
if %secs% lss 0 set /a mins = %mins% - 1 & set /a secs = 60%secs%
if %mins% lss 0 set /a hours = %hours% - 1 & set /a mins = 60%mins%
if %hours% lss 0 set /a hours = 24%hours%
if 1%ms% lss 100 set ms=0%ms%

:: Mission accomplished
set /a totalsecs = %hours%*3600 + %mins%*60 + %secs%

call :echo -it:true -ri:ResultTime -v1:"%hours%:%mins%:%secs%.%ms%" -v2:"%totalsecs%.%ms%" -rc:08 -vc:0F -ln:false
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит проблемные скрипты
rem ---------------------------------------------
:echo_broken_scripts _cnt _res_id _color
setlocal
set _cnt=%~1
set _res_id=%~2
set _color=%~3

rem если не мантра "red/green/refactor" и не задан единственный тест и есть что выводить
if /i "%p_green_line%" EQU "%VL_FALSE%" if "%p_test_script%" EQU "" if %_cnt% GTR -1 (
	set /a "l_cnt=%_cnt%+1"
	call :echo -it:true -ri:%_res_id% -v1:!l_cnt! -rc:0F
	for /l %%j in (0,1,%_cnt%) do (
		if exist "!%4[%%j]#Script!" (
			if /i "%4" EQU "faileds" (
				call :echo -it:true -ri:TestBrokenFull -v1:"!%4[%%j]#Script!" -v2:"!%4[%%j]#TestCase!" -v3:"!%4[%%j]#ExitCode!" -rc:%_color% -rs:4
			) else (
				call :echo -it:true -ri:TestBroken -v1:"!%4[%%j]#Script!" -rc:%_color% -rs:4
			)
		)
	)
	echo.
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит инструкцию пользователя по работе с 
rem утилитой
rem ---------------------------------------------
:test_help
setlocal
for /f %%i in ("%CUR_DIR%%DIR_SEP%%DEF_SRC_PATH%") do set l_src_dir=%%~dpnxi
call :echo -rf:"%help_file%" -ri:ScriptHeader -v1:"%g_script_header%" -rc:0E -be:1
call :echo -rf:"%help_file%" -ri:ScriptDescription -rc:0F
call :echo -rf:"%help_file%" -ri:ScriptUsage -v1:"%g_script_name%" -rc:0F -be:1 -ae:1
call :echo -rf:"%help_file%" -ri:ExecKeys -rc:0F
call :echo -rf:"%help_file%" -ri:KeyHelp -v1:"--help" -c1:0B -rs:4
call :echo -rf:"%help_file%" -ri:KeySrcPath -v1:"-sp" -v2:"%l_src_dir%" -c1:0B -c2:0F -rs:4
call :echo -rf:"%help_file%" -ri:KeySrcScript -v1:"-ss" -c1:0B -rs:4
call :echo -rf:"%help_file%" -ri:KeyTestScript -v1:"-ts" -c1:0B -rs:4
call :echo -rf:"%help_file%" -ri:KeyLocale -v1:"-lc" -v2:%locale% -c1:0B -c2:0F -rs:4
call :echo -rf:"%help_file%" -ri:KeyGreenLine -v1:"-gl" -v2:%p_green_line% -v4:%VL_TRUE% -v5:%VL_FALSE% -c1:0B -c2:0F -c4:0F -c5:0F -rs:4
call :echo -rf:"%help_file%" -ri:KeyAbortOnFail -v1:"-af" -v2:%p_abort_on_fail% -v4:%VL_TRUE% -v5:%VL_FALSE% -c1:0B -c2:0F -c4:0F -c5:0F -rs:4
call :echo -rf:"%help_file%" -ri:KeySupressOutput -v1:"-so" -v2:%p_supress_output% -v4:%VL_TRUE% -v5:%VL_FALSE% -c1:0B -c2:0F -c4:0F -c5:0F -rs:4
call :echo -rf:"%help_file%" -ri:ExecExamples -rc:0F -be:1
call :echo -rf:"%help_file%" -ri:ExecExample1 -v1:"%g_script_name%" -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation1 -rs:6
call :echo -rf:"%help_file%" -ri:ExecExample2 -v1:"%g_script_name%" -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation2 -rs:6
call :echo -rf:"%help_file%" -ri:ExecExample3 -v1:"%g_script_name%" -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation3 -rs:6
call :echo -rf:"%help_file%" -ri:ExecExample4 -v1:"%g_script_name%" -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation4 -rs:6
call :echo -rf:"%help_file%" -ri:ExecExample5 -v1:"%g_script_name%" -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation5 -rs:6
call :echo -rf:"%help_file%" -ri:ExecExample6 -v1:"%g_script_name%" -v2:%VL_TRUE% -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation6 -rs:6
call :echo -rf:"%help_file%" -ri:ExecExample7 -v1:"%g_script_name%" -v2:%VL_TRUE% -v3:%VL_FALSE% -rc:0F -rs:4 & call :echo -rf:"%help_file%" -ri:ExecExplanation7 -rs:6 -ae:1
pause
call :echo -rf:"%help_file%" -ri:ForTesters -rc:0F -be:1
call :echo -rf:"%help_file%" -ri:TestFunc1 -be:1
call :echo -rf:"%help_file%" -ri:TestsInfo -v1:%RESULT_OK% -v2:%RESULT_FAILED% -v3:%RESULT_SKIPPED% -v4:%RESULT_ERROR% -vc:0F -rs:4
call :get_res_val -ri:ResultOk & set hlp_ok=!res_val!
call :get_res_val -ri:ResultFailed & set hlp_failed=!res_val!
call :get_res_val -ri:ResultSkipped & set hlp_skipped=!res_val!
call :get_res_val -ri:ResultError & set hlp_error=!res_val!
call :echo -rf:"%help_file%" -ri:TestsResultsInfo -v1:%hlp_ok% -v2:%hlp_failed% -v3:%hlp_skipped% -v4:%hlp_error% -c1:0A -c2:0C -c3:0B -c4:0E  -rs:4
call :echo -rf:"%help_file%" -ri:TestFunc2 -be:1
call :echo -rf:"%help_file%" -ri:TestsPrefixInfo -v1:%TST_PREFIX% -v2:%WB_PREFIX% -vc:0F -rs:4
call :echo -rf:"%help_file%" -ri:TestFunc3 -be:1
call :echo -rf:"%help_file%" -ri:TestsDirsInfo -v1:%l_src_dir% -v2:%CUR_DIR% -vc:0F -rs:4
call :echo -rf:"%help_file%" -ri:TestFunc4 -be:1
call :echo -rf:"%help_file%" -ri:TestsSpecScripts -v1:%CUR_DIR% -v2:%SETUP_FILE% -v3:%TEARDOWN_FILE% -v4:%ORD_PREPEND% -v5:%ORD_APPEND% -vc:0F -rs:4
call :echo -rf:"%help_file%" -ri:TestFunc5 -be:1
call :echo -rf:"%help_file%" -ri:TestsParamsInfo -rs:4
call :echo -rf:"%help_file%" -ri:TestFunc6 -be:1
call :echo -rf:"%help_file%" -ri:TestsRGRInfo -v1:%TR_OK% -v2:%TR_FAILED% -v3:%TR_SKIPPED% -v4:%TR_ERROR% -c1:0A -c2:0C -c3:0B -c4:0E -rs:4
call :echo -rf:"%help_file%" -ri:TestsExamples -v1:%CUR_DIR% -vc:0F -be:1 -rs:4
endlocal & exit /b 0

rem ---------------- EOF test.cmd ----------------