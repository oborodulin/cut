@Echo Off
rem {Copyright}
rem {License}
rem Сценарий глобальных определений и констант

::Define a BS variable containing a backspace (0x08) character
for /f %%A in ('"prompt $H & echo on & for %%B in (1) do rem"') do set "BS=%%A"
rem разделитель каталогов ОС
set DIR_SEP=\
rem разделитель файлов ОС
set PATH_SEP=;
rem уровни логгирования: 0 - сообщения в файл, 1 - сообщения на экран, 2 - ошибки, 3 - предупреждения, 4 - информация, 5 - отладка
set LL_FILE=0
set LL_CON=1
set LL_ERR=2
set LL_WRN=3
set LL_INF=4
set LL_DBG=5
rem уровень логгирования по умолчанию: ошибки
set DEF_LOG_LEVEL=%LL_ERR%
rem логические константы
set VL_TRUE=true
set VL_FALSE=false
rem режимы выполнения системы: эмуляции, тестовый, промышленный, отладки
set EM_EML=EML
set EM_TST=TST
set EM_RUN=RUN
set EM_DBG=DBG
rem коды возврата текущего режима выполнения
set CODE_EML=0
set CODE_TST=1
set CODE_RUN=2
set CODE_DBG=3
rem задержка выбора в меню по умолчанию (сек.)
set DEF_DELAY=20
set SHORT_DELAY=10
rem признаки простого выбора пользователя в меню
set YN_CHOICE=yn
set YES=1
set NO=2
rem команды работы с реестром
set RC_GET=GET
set RC_SET=SET
set RC_ADD=ADD
set RC_DEL=DEL
rem предопределённые разделы реестра
set RH_HKLM=HKLM
set RH_HKCU=HKCU
rem направления конфертации слешей в путях к файлам
set CSD_WIN=WIN
set CSD_NIX=NIX
rem признаки конвертации регистра строки
set CM_UPPER=UPPER
set CM_LOWER=LOWER
rem форматы представления даты и времени
set DF_DATE_TIME=DATE_TIME
set DF_DATE_CODE=DATE_CODE
set DF_DATE=DATE
set DF_TIME=TIME
rem архитектуры (разрядность) процессора и ОС
set PA_X86=x86
set PA_X64=x64

rem ---------------- EOF definitions.cmd ----------------
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
set test_param_defs="-lc,locale;-em,EXEC_MODE,%EM_TST%;-sp,p_src_path,%DEF_SRC_PATH%;-tp,p_tst_path,%DEF_TST_PATH%;-ss,p_src_script;-ts,p_test_script;-gl,p_green_line,%VL_FALSE%;-af,p_abort_on_fail,%VL_FALSE%;-so,p_supress_output,%VL_TRUE%"
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
	set l_src_dir=%p_src_path%%DIR_SEP%!l_test_dir_ptrn:%p_tst_path%%DIR_SEP%=!
	rem echo "!l_src_dir!"
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

rem ---------------- EOF test.cmd ----------------rem {Copyright}
rem {License}
rem Сценарий работы с параметрами процедур и других сценариев

rem ---------------------------------------------
rem Разбирает и устанавливает значения переданным 
rem параметрам в заданной области видимости
rem ---------------------------------------------
:parse_params _scope _prm_defs %*
set _prm_scope=%~1
set _prm_defs=%~2

call :get_prm_scope "%_prm_scope%"

rem РАЗБОР ОПРЕДЕЛЕНИЙ ПАРАМЕТРОВ:
rem если ранее определения параметров были разобраны переходим к сбросу параметров и формированию значений
if defined g_prms[%prm_scope%]#Count goto end_param_defs
set l_prm_defs=%_prm_defs%
set "prm=0"
:param_defs_loop
for /f "tokens=1* delims=;" %%i in ("%l_prm_defs%") do (
	rem echo param definition: "%%i"
	set l_prm_def=%%i
	for /f "tokens=1-5 delims=," %%a in ("!l_prm_def!") do (
		rem echo param definition parts: "%%a" "%%b" "%%c" "%%d" "%%e"
		set l_key=%%~a
		if not defined l_key set "p_def_prm_err=%VL_TRUE%" & exit /b 2
		set l_name=%%~b
		if not defined l_name set "p_def_prm_err=%VL_TRUE%" & exit /b 2
		set l_def_val=%%~c
		set l_empty_var=%%~d
		set l_empty_val=%%~d
		set l_count_var=%%~e
		set g_prms[%prm_scope%][!prm!]#Key=!l_key!
		set g_prms[%prm_scope%][!prm!]#Name=!l_name!
		set g_prms[%prm_scope%][!prm!]#DefValue=
		set g_prms[%prm_scope%][!prm!]#EmptyVar=
		set g_prms[%prm_scope%][!prm!]#EmptyVal=
		set g_prms[%prm_scope%][!prm!]#CountVar=
		if defined l_def_val (
			rem если указано значение по умолчанию только в случае отсутствия параметра
			if "!l_def_val!" EQU "#" (
				rem echo not defined: "%%a" "%%b" "%%c" "%%d" "%%e"
				if defined l_empty_val if "!l_empty_val!" NEQ "~" set g_prms[%prm_scope%][!prm!]#EmptyVal=!l_empty_val!
			) else (
				if "!l_def_val!" NEQ "~" set g_prms[%prm_scope%][!prm!]#DefValue=!l_def_val!
				if defined l_empty_var (
					if "!l_empty_var!" NEQ "~" set g_prms[%prm_scope%][!prm!]#EmptyVar=!l_empty_var!
					if defined l_count_var if "!l_count_var!" NEQ "~" set g_prms[%prm_scope%][!prm!]#CountVar=!l_count_var!
				)
			)
		)
		set g_prms[%prm_scope%][!prm!]#Count=1
		set /a "prm+=1"
	)
	set l_prm_defs=%%j
)
if defined l_prm_defs goto :param_defs_loop
set /a "g_prms[%prm_scope%]#Count=%prm%-1"

:end_param_defs
rem СБРОС ПАРАМЕТРОВ:
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem echo reset: "!g_prms[%prm_scope%][%%n]#Key!" "!g_prms[%prm_scope%][%%n]#Name!" "!g_prms[%prm_scope%][%%n]#DefValue!"
	if defined !g_prms[%prm_scope%][%%n]#CountVar! (
		for /l %%i in (1,1,!g_prms[%prm_scope%][%%n]#Count!) do (
			set !g_prms[%prm_scope%][%%n]#Name!%%i=
			set g_prms[%prm_scope%][%%n]#Value%%i=
		)
		set !g_prms[%prm_scope%][%%n]#CountVar!=
		set g_prms[%prm_scope%][%%n]#Count=1
	) else if defined !g_prms[%prm_scope%][%%n]#Name! (
		rem если параметр определён,
		if not defined g_prms[%prm_scope%][%%n]#EmptyVal (
			rem то сбрасываем его только если не задано значение для не определённого параметра
			rem echo reset if not empty value: "!g_prms[%prm_scope%][%%n]#Name!"
			set !g_prms[%prm_scope%][%%n]#Name!=
			set g_prms[%prm_scope%][%%n]#Value=
		)
	)
)
rem УСТАНОВКА ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ: без контроля определения параметров
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem если указано значение по умолчанию
	if defined g_prms[%prm_scope%][%%n]#DefValue (
		rem echo set default value: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#DefValue!
		set !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#DefValue!
		set g_prms[%prm_scope%][%%n]#Value=!g_prms[%prm_scope%][%%n]#DefValue!
	)
)
rem ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПАРАМЕТРОВ:
rem переходим к аргументам-значениям параметров
shift
shift
:start_params_parse
set p_prm=%~1
set p_key=%p_prm:~0,3%
set p_val=%p_prm:~4%
set p_val=%p_val:"=%

if [%p_prm%] EQU [] goto end_params_parse

rem разбор параметров вывода справки
if [%p_prm%] EQU [/?] set "p_key_help=%VL_TRUE%" & exit /b 1
if /i [%p_prm%] EQU [--help] set "p_key_help=%VL_TRUE%" & exit /b 1

rem echo params key=value: %p_key%=%p_val%
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem разбор перечисляемых параметров
	if "!g_prms[%prm_scope%][%%n]#Key:~0,2!" EQU "!g_prms[%prm_scope%][%%n]#Key:~0,3!" (
		if "!g_prms[%prm_scope%][%%n]#CountVar!" NEQ "" (
			rem если полное совпадение ключа
			rem echo if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!!g_prms[%prm_scope%][%%n]#Count!" 
			if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!!g_prms[%prm_scope%][%%n]#Count!" (
				set !g_prms[%prm_scope%][%%n]#Name!!g_prms[%prm_scope%][%%n]#Count!=%p_val%
				set g_prms[%prm_scope%][%%n]#Value!g_prms[%prm_scope%][%%n]#Count!=%p_val%
				set !g_prms[%prm_scope%][%%n]#CountVar!=!g_prms[%prm_scope%][%%n]#Count!
				set /a "g_prms[%prm_scope%][%%n]#Count+=1"
			) else (
				rem проверка неполного совпадения ключа
				set half_key=%p_key:~0,2%
				set key_num=%p_key:~2%
				if /i "!half_key!" EQU "!g_prms[%prm_scope%][%%n]#Key!" (
					set "l_check_key_num="&for /f "delims=0123456789" %%i in ("!key_num!") do set l_check_key_num=%%i
					if not defined l_check_key_num (
						if !key_num! GTR !g_prms[%prm_scope%][%%n]#Count! (
							set g_prms[%prm_scope%][%%n]#Count=!key_num!
							set !g_prms[%prm_scope%][%%n]#Name!!g_prms[%prm_scope%][%%n]#Count!=%p_val%
							set g_prms[%prm_scope%][%%n]#Value!g_prms[%prm_scope%][%%n]#Count!=%p_val%
							set !g_prms[%prm_scope%][%%n]#CountVar!=!g_prms[%prm_scope%][%%n]#Count!
							set /a "g_prms[%prm_scope%][%%n]#Count+=1"
						)	
					)
				)
			)
		)
	) else if /i "%p_key%" EQU "!g_prms[%prm_scope%][%%n]#Key!" (
		rem разбор одиночных параметров
		if defined p_val (
			rem если указано значение для не определённого параметра
			if defined g_prms[%prm_scope%][%%n]#EmptyVal (
				rem то устанавливаем заднное значение, только если он не определён
				if not defined !g_prms[%prm_scope%][%%n]#Name! (
					rem echo undefined param set value: !g_prms[%prm_scope%][%%n]#Name!=%p_val%
					set !g_prms[%prm_scope%][%%n]#Name!=%p_val%
					set g_prms[%prm_scope%][%%n]#Value=%p_val%
				)
			) else (
				set !g_prms[%prm_scope%][%%n]#Name!=%p_val%
				set g_prms[%prm_scope%][%%n]#Value=%p_val%
			)
		) else (
			rem установка признака пустого значения
			if "!g_prms[%prm_scope%][%%n]#EmptyVar!" NEQ "" set !g_prms[%prm_scope%][%%n]#EmptyVar!=true
		)
	)
)
shift
goto start_params_parse
:end_params_parse
rem УСТАНОВКА ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ: с контролем определения параметров
for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	rem устанавливаем значение только, если задано значение для не определённого параметра и он не определён
	if defined g_prms[%prm_scope%][%%n]#EmptyVal if not defined !g_prms[%prm_scope%][%%n]#Name! (
		rem echo set empty value: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#EmptyVal!
		set !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#EmptyVal!
		set g_prms[%prm_scope%][%%n]#Value=!g_prms[%prm_scope%][%%n]#EmptyVal!
	)
)
exit /b 0

rem ---------------------------------------------
rem Печатает параметры и их значения, в т.ч.
rem значения по умолчанию
rem ---------------------------------------------
:print_params _scope
setlocal
set _prm_scope=%~1
call :get_prm_scope "%_prm_scope%"

for /l %%n in (0,1,!g_prms[%prm_scope%]#Count!) do (
	set l_start_symb=
	set l_end_bracket=
	if "!g_prms[%prm_scope%][%%n]#CountVar!" NEQ "" (
		for /l %%k in (1,1,!g_prms[%prm_scope%][%%n]#Count!) do (
			if defined !g_prms[%prm_scope%][%%n]#Name!%%k echo %prm_scope%: !g_prms[%prm_scope%][%%n]#Name!%%k=!g_prms[%prm_scope%][%%n]#Value%%k!
		)
	) else if defined !g_prms[%prm_scope%][%%n]#Name! (
				rem для вывода круглых скобок echo должны быть на отдельных строках
				echo | set /p "dummyName=%prm_scope%: !g_prms[%prm_scope%][%%n]#Name!=!g_prms[%prm_scope%][%%n]#Value! "
				set l_start_symb=^(
				if defined g_prms[%prm_scope%][%%n]#DefValue (
					echo | set /p "dummyName=!l_start_symb!!g_prms[%prm_scope%][%%n]#DefValue!"
					set "l_start_symb=,"
					set l_end_bracket=^)
				) else if defined g_prms[%prm_scope%][%%n]#EmptyVal (
					echo | set /p "dummyName=!l_start_symb!#!g_prms[%prm_scope%][%%n]#EmptyVal!"
					set "l_start_symb=,"
					set l_end_bracket=^)
				)
				if defined g_prms[%prm_scope%][%%n]#EmptyVar (
					echo | set /p "dummyName=!l_start_symb!!g_prms[%prm_scope%][%%n]#EmptyVar!"
					set l_end_bracket=^)
				)
				if defined l_end_bracket (
					echo !l_end_bracket!
				) else (
					echo.
				)
			)
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает нормированный идентификатор области 
rem видимости параметров
rem ---------------------------------------------
:get_prm_scope _scope
setlocal
set _proc_name=%~0
set _prm_scope=%~1
rem если область видимости процедура
if "%_prm_scope:~0,1%" EQU ":" (
	set l_prm_scope=%_prm_scope:~1%
) else if exist "%_prm_scope%" (
	rem если область видимости сценарий
	for /f %%i in ("%_prm_scope%") do set l_prm_scope=%%~ni
)
endlocal & set %_proc_name:~5%=%l_prm_scope%
exit /b 0
rem ---------------- EOF params.cmd ----------------
rem {Copyright}
rem {License}
rem Сценарий системных утилит

rem ---------------------------------------------
rem Возвращает архитектуру процессора (x86|x64)
rem ---------------------------------------------
:get_proc_arch
setlocal
set _proc_name=%~0

rem Определяем разрядность системы (http://social.technet.microsoft.com/Forums/windowsserver/en-US/cd44d6d3-bdfa-4970-b7db-e3ee746d6213/determine-%PA_X86%-or-%PA_X64%-from-registry?forum=winserverManagement)
call :reg -oc:%RC_GET% -vn:PROCESSOR_ARCHITECTURE
if "%reg%" EQU "" call :echo -ri:ProcArchAutoDefError -rl:0FILE & exit /b 1

rem http://social.msdn.microsoft.com/Forums/en-US/5a316848-1ec3-4d01-a395-7c5b17756239/determining-current-cpu-architecture-x32-or-%PA_X64%
if "%reg%" EQU "%PA_X86%" (set l_proc_arch=%reg%) else (set l_proc_arch=%PA_X64%)
endlocal & set "%_proc_name:~5%=%l_proc_arch%"
exit /b 0

rem ---------------------------------------------
rem Возвращает локаль системы (ru|en|...)
rem ---------------------------------------------
:get_locale
setlocal
set _proc_name=%~0
FOR /F "delims==" %%A IN ('systeminfo.exe ^|  findstr ";"') do  (
	FOR /F "usebackq tokens=2-3 delims=:;" %%B in (`echo %%A`) do (
		set VERBOSE_SYSTEM_LOCALE=%%C
		REM Removing useless leading spaces ...
		FOR /F "usebackq tokens=1 delims= " %%D in (`echo %%B`) do (
			set SYSTEM_LOCALE=%%D
			goto :locale_get_success
		)
		rem set SYSTEM_LOCALE_WITH_SEMICOLON=!SYSTEM_LOCALE!;
		rem set | findstr /I locale
		REM No need to handle second line, quit after first one
	)
)
endlocal & exit /b 1

:locale_get_success
endlocal & set "%_proc_name:~5%=%SYSTEM_LOCALE%"
exit /b 0

rem ---------------------------------------------
rem Возвращает текущую дату или время в формате ISO
rem http://ss64.com/nt/syntax-getdate.html
rem ---------------------------------------------
:get_iso_date
setlocal
set _proc_name=%~0
set _date_format=%~1

if "%_date_format%" EQU "" endlocal & exit /b 1

:: Check WMIC is available
WMIC.EXE Alias /? >NUL 2>&1 || (endlocal & exit /b 1)

:: Use WMIC to retrieve date and time
FOR /F "skip=1 tokens=1-6" %%G IN ('WMIC Path Win32_LocalTime Get Day^,Hour^,Minute^,Month^,Second^,Year /Format:table') DO (
	IF "%%~L"=="" goto s_done
	Set _yyyy=%%L
	Set _mm=00%%J
	Set _dd=00%%G
	Set _hour=00%%H
	SET _minute=00%%I
)
:s_done

:: Pad digits with leading zeros
Set _mm=%_mm:~-2%
Set _dd=%_dd:~-2%
Set _hour=%_hour:~-2%
Set _minute=%_minute:~-2%

:: Display the date/time in ISO 8601 format:
if "%_date_format%" EQU "%DF_DATE_TIME%" Set l_isodate=%_yyyy%-%_mm%-%_dd% %_hour%:%_minute%
if "%_date_format%" EQU "%DF_DATE_CODE%" Set l_isodate=%_yyyy%%_mm%%_dd%
if "%_date_format%" EQU "%DF_DATE%" Set l_isodate=%_yyyy%-%_mm%-%_dd%
if "%_date_format%" EQU "%DF_TIME%" Set l_isodate=%_hour%:%_minute%

rem :get_date_error
	rem Echo Ошибка формирования текущей даты. 1>&2

endlocal & set "%_proc_name:~5%=%l_isodate%"
exit /b 0

rem ---------------------------------------------
rem Выводит наименование неявной цели выполнения
rem ---------------------------------------------
:print_exec_name
setlocal
set _proc_name=%~1

call :get_exec_name %_proc_name%
set $exec=%_proc_name:goal=%
if /i "%$exec%" NEQ "%_proc_name%" (
	call :echo -ri:ExecGoal -v1:"%exec_name%" -ae:1
) else (
	call :echo -ri:ExecPhaseId -v1:"%exec_name%" -ae:1
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает наименование этапа выполнения фазы/цели
rem (по наименованию процедуры)
rem ---------------------------------------------
:get_exec_name
setlocal
set _exec_name=%~0
set _proc_name=%~1

set $exec=%_proc_name:goal=%
if /i "%$exec%" NEQ "%_proc_name%" (
	set l_exec_name=%_proc_name:~6%
) else (
	set $exec=%_proc_name:phase=%
	if /i "!$exec!" NEQ "%_proc_name%" (
		set l_exec_name=%_proc_name:~7%
	) else (
		set l_exec_name=%_proc_name:~5%
	)
)
set l_exec_name=%l_exec_name:_=-%
endlocal & set %_exec_name:~5%=%l_exec_name%
exit /b 0

rem ---------------------------------------------
rem Запрашивает подтверждение выполнения процесса
rem ---------------------------------------------
:choice_process
setlocal
set _proc_name=%~0
set _exec_name=%~1
set _res_id=%~2
set _delay=%~3
set _def_choice=%~4
set _res_val=%~5
set _choice=%~6

if not defined _res_id if not defined _res_val set _res_id=ProcessingChoice
if not defined _delay set _delay=%DEF_DELAY%
if not defined _def_choice set _def_choice=Y
if not defined _choice set _choice=%YN_CHOICE%

if defined _exec_name (
	set l_exec_name=%_exec_name:~0,1%
	if "%l_exec_name%" EQU ":" (
		call :get_exec_name "%l_exec_name%"
	) else (
		set exec_name=%_exec_name%
	)
)
if defined _res_id (
	call :get_res_val -rf:"%menus_file%" -ri:%_res_id% -v1:%_delay% -v2:"%exec_name%"
) else (
	set res_val=%_res_val%
)
rem ChangeColor 15 0
%ChangeColor_15_0%
1>nul chcp 1251
Choice /C %_choice% /T %_delay% /D %_def_choice% /M "%res_val%"
set l_result=%ERRORLEVEL%
rem echo l_result="%l_result%"
endlocal & (set "%_proc_name:~8%=%exec_name%" & set "%_proc_name:~1,6%=%l_result%" & exit /b %l_result%)

rem ---------------- EOF utils.cmd ----------------
@Echo Off
rem {Copyright}
rem {License}
rem Сценарий получения и отображения ресурсов (строковых) заданным цветом и возможностью логгирования

setlocal EnableExtensions EnableDelayedExpansion

rem УСТАНОВКА И ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ:
set g_script_name=%~nx0

call :echo %*
if ERRORLEVEL 1 endlocal & exit /b 1

endlocal & exit /b 0

rem ---------------------------------------------
rem Получает и отображает ресурс (строковый)
rem ---------------------------------------------
:echo %*
setlocal
rem Устанавливаем все необходимые параметры и ресурсы для работы скрипта, и проверяем их корректность
call :echo_res_setup %*
call :echo_res_check_setup
if ERRORLEVEL 1 endlocal & exit /b 1

if defined p_cmd if /i "%p_cmd%" EQU "GET" call :get_res_val & echo !res_val! & endlocal & exit /b %ERRORLEVEL%
rem echo "%script_hdr%" "%res_path%" "%p_res_id%"

rem если передано значение ресурса
if defined res_val (
	if /i "%categ_name%" NEQ "" set res_val=%categ_name%: %res_val%
	call :set_res_color %res_color% 
	call :echo_level_res "%res_val%" "%ln%" "%log_lvl%" "%categ_num%"
) else if /i "%p_res_val_empty%" EQU "%VL_TRUE%" (
	call :echo_level_res "%res_val%" "%ln%" "%log_lvl%" "%categ_num%"
) else (
	rem иначе получаем ресурс по его ИД
	call :get_res_val
	rem echo !res_code! !res_categ! !categ_num! !categ_name! !res_val! "!result!"
	if ERRORLEVEL 1 endlocal & exit /b %ERRORLEVEL%

	rem если не только вывод в файл
	if /i "!categ_name!" NEQ "%CTG_FILE%" (
		rem определяем цвет символов и формат вывода по категории ресурса
		if /i "!categ_name!" EQU "%CTG_ERR%" (
			rem ресурс-ошибка
			set l_res_color=0C
			set res_val=!categ_name!-!res_code!: %p_res_id%: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_WRN%" (
			rem ресурс-предупреждение
			set l_res_color=0E
			set res_val=!categ_name!-!res_code!: %p_res_id%: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_INF%" (
			rem ресурс-информация
			set l_res_color=09
			set res_val=!categ_name!-!res_code!: !res_val!
		) else if /i "!categ_name!" EQU "%CTG_FINE%" (
			rem ресурс-отладка
			set l_res_color=08
			set res_val=!categ_name!-!res_code!: !res_val!
		) else (
			set l_res_color=%res_color%
		)
		call :set_res_color !l_res_color!
		call :echo_level_res "!res_val!" "%ln%" "%log_lvl%" "!categ_num!"
	)
)
call :echo_log "%log_path%" "%res_val%" "%categ_num%" "%log_lvl%" "%script_hdr%"
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит ресурс в лог-файл
rem ---------------------------------------------
:echo_log _log_path _res_val _categ_num _log_lvl _script_hdr
setlocal
set _log_path=%~1
set _res_val=%~2
set _categ_num=%~3
set _log_lvl=%~4
set _script_hdr=%~5

rem если не указан лог файл, то завершаем сценарий
if "%_log_path%" EQU "" endlocal & exit /b 1

if not exist "%_log_path%" (
	echo %_script_hdr% > "%_log_path%"
	echo. >> "%_log_path%"
)
rem FOR /F "usebackq tokens=*" %%A IN (`%modules_dir%iso_date.cmd -df:DATE_TIME 2^>nul`) DO set iso_date_time=%%A
if "%_categ_num%" EQU "" set _categ_num=0
set l_res_val=%DATE% %TIME%: %_res_val%
rem для вывода круглых скобок echo должны быть на отдельных строках
if defined _log_lvl (
	if %_categ_num% LEQ %_log_lvl% echo %l_res_val% >> "%_log_path%"
) else (
	echo %l_res_val% >> "%_log_path%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает значение ресурса (строкового)
rem (устанавливает: 	g_res[%res_name%][%p_res_id%]#Val
rem						g_res[%res_name%][%p_res_id%]#Code
rem						g_res[%res_name%][%p_res_id%]#Categ
rem						g_res[%res_name%][%p_res_id%]#CategNum
rem						g_res[%res_name%][%p_res_id%]#CategName)
rem ---------------------------------------------
:get_res_val _proc_param...
set _proc_name=%~0
set _proc_param=%~1

rem если передан хотя бы один параметр, прогоняем их все через установку
if "%_proc_param%" NEQ "" call :echo_res_setup %*
for /f %%i in ("%res_path%") do set res_name=%%~ni
set g_res_output_cnt=

rem если ресурс был ранее определён, то используем его
if defined g_res[%res_name%][%p_res_id%]#Val (
	set res_code=!g_res[%res_name%][%p_res_id%]#Code!
	set res_categ=!g_res[%res_name%][%p_res_id%]#Categ!
	set categ_num=!g_res[%res_name%][%p_res_id%]#CategNum!
	set categ_name=!g_res[%res_name%][%p_res_id%]#CategName!
	set res_val=!g_res[%res_name%][%p_res_id%]#Val!
	goto res_found
) else (
	rem иначе выполняем поиск ресурса
	for /F "usebackq eol=; skip=1 tokens=1-4 delims=	" %%i in ("%res_path%") do (
		rem echo Из ресурсного файла "%res_path%": "%%i" "%%j" "%%k"  "%%l"
		set l_id=%%i
		set l_code=%%j
		set l_categ=%%k
		set l_val=%%l

		if /i "!l_id!" EQU "%p_res_id%" (
			set res_code=!l_code!
			if not defined res_categ (
				set res_categ=!l_categ!
				set categ_num=!l_categ:~0,1!
				set categ_name=!l_categ:~1!
			)
			set res_val=!l_val!
			set g_res[%res_name%][%p_res_id%]#Val=!l_val!
			set g_res[%res_name%][%p_res_id%]#Code=!l_code!
			set g_res[%res_name%][%p_res_id%]#Categ=!res_categ!
			set g_res[%res_name%][%p_res_id%]#CategNum=!categ_num!
			set g_res[%res_name%][%p_res_id%]#CategName=!categ_name!
			goto res_found
		)
	)
)
set l_err_msg=ERR -1: Не найден ресурс [ИД=%p_res_id%] в файле "%res_path%". Проверьте, пожалуйста, его наличие.
rem если не только вывод в файл
if /i "%categ_name%" NEQ "%CTG_FILE%" (
	rem ChangeColor 12 0
	%ChangeColor_12_0%
	1>nul chcp %code_page% & echo !l_err_msg!
) else (
	call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
)
exit /b 1

:res_found
rem если не определён цвет для переменных, то сразу подставляем переменные в строку
set is_color_defined=%VL_FALSE%
if defined p_val_color (set is_color_defined=%VL_TRUE%) else (for /l %%i in (1,1,%colors_cnt%) do if defined p_val_color_%%i set "is_color_defined=%VL_TRUE%" & goto :color_defined)

:color_defined
if /i "%is_color_defined%" NEQ "%VL_TRUE%" goto res_val_create

rem если определён цвет для переменных, то формируем последовательность вывода
call :create_res_output "%res_name%" "%p_res_id%" "%res_val%"
goto end_get_res_val

:res_val_create
rem подставляем значения переменных ресурса
for /l %%i in (1,1,%values_cnt%) do if defined p_val_%%i (call :res_bind_var "!res_val!" {%V_SYMB%%%i} p_val_%%i & set res_val=!bind_var!) else (goto end_get_res_val)

:end_get_res_val
set %_proc_name:~5%=!res_val!
exit /b 0

rem ---------------------------------------------
rem Подставляет значение переменной ресурса
rem ---------------------------------------------
:res_bind_var _res_val _var _val
setlocal
set _proc_name=%~0
set _res_val=%~1
set _var=%~2
set _val=!%3!

set _res_val=!_res_val:%_var%=%_val%!

endlocal & set %_proc_name:~5%=%_res_val%
exit /b 0

rem ---------------------------------------------
rem Создаёт последовательность вывода ресурса
rem (устанавливает: 	g_res_tpl[%_res_name%][%_res_id%][0]#Cnt
rem 					g_res_tpl[%_res_name%][%_res_id%][!er!]#Part
rem 					g_res_output_cnt
rem						g_res_output[%%j]#Part
rem 					g_res_output[%%j]#Color)
rem ---------------------------------------------
:create_res_output _res_name _res_id _res_val
set _res_name=%~1
set _res_id=%~2
set _res_val=%~3

rem если определён размер шаблона последовательности вывода, то переходим к её формированию
if defined g_res_tpl[%_res_name%][%_res_id%][0]#Cnt goto res_parts_loop

rem иначе - опредляем шаблон
set l_tmp_val=%_res_val%
set er=0
set l_vars_cnt=0
:res_output_loop
for /f "tokens=1* delims={}" %%a in ("%l_tmp_val%") do (
	set l_part=%%a
	rem echo "!l_part!"
	rem определяем подстановочная ли переменная и если да, то вычисляем их количество в строковом ресурсе
	if "!l_part:~0,1!" EQU "!V_SYMB!" (
		set l_var_num=!l_part:~1!
		set "l_check_var_num="&for /f "delims=0123456789" %%i in ("!l_var_num!") do set l_check_var_num=%%i
		if not defined l_check_var_num if !l_var_num! GEQ !l_vars_cnt! set l_vars_cnt=!l_var_num!
	)
	set g_res_tpl[%_res_name%][%_res_id%][!er!]#Part=!l_part!
	set l_tmp_val=%%b
 	set /a "er+=1"
)
if defined l_tmp_val goto :res_output_loop
set /a "g_res_tpl[%_res_name%][%_res_id%][0]#Cnt=%er%-1"

:res_parts_loop
set g_res_output_cnt=!g_res_tpl[%_res_name%][%_res_id%][0]#Cnt!

if %g_res_output_cnt% EQU 0 set "g_res_output_cnt=" & exit /b 0
rem echo "%g_res_output_cnt%"

for /l %%j in (0,1,%g_res_output_cnt%) do (
	set l_res_part=!g_res_tpl[%_res_name%][%_res_id%][%%j]#Part!

	set $check_part=!l_res_part!
	for /l %%i in (1,1,%l_vars_cnt%) do (
		if "!l_res_part!" EQU "!V_SYMB!%%i" (
			if defined p_val_%%i (
				set "$check_part=!p_val_%%i!" & set "l_part_color=!p_val_color_%%i!"
			) else (
				set "$check_part=" & set "l_part_color="
			)
		)
	)
	if not defined l_part_color set l_part_color=%p_val_color%
	rem если не подстановочная переменная, то устанавливаем цвет ресурса
	if "!$check_part!" EQU "!l_res_part!" (
		set g_res_output[%%j]#Part=!l_res_part!
		set g_res_output[%%j]#Color=%res_color%
	) else (
		set g_res_output[%%j]#Part=!$check_part!
		set g_res_output[%%j]#Color=!l_part_color!
	)
)
exit /b 0

rem ---------------------------------------------
rem Выводит ресурс в завиимости от режима выполнения
rem и уровня логгирования
rem (в тестовом режиме сообщения выводятся только
rem с признаком игнорирования тестового режима)
rem ---------------------------------------------
:echo_level_res _res_val _ln _log_lvl _categ_num
setlocal
set _res_val=%~1
set _ln=%~2
set _log_lvl=%~3
set _categ_num=%~4
rem если не в режиме тестирования или в нём, но задано игнорирование этого режима, то выводим ресурс
if /i "%EXEC_MODE%" NEQ "%EM_TST%" goto echo_res_any_case
if /i "%ignore_test_exec_mode%" NEQ "%VL_TRUE%" endlocal & exit /b 0
:echo_res_any_case
if "%_categ_num%" EQU "" set _categ_num=0
rem если задан уровень логгирования, то контролируем его
if "%_log_lvl%" NEQ "" (
	rem echo if %_categ_num% LEQ %_log_lvl% call :echo_res_val "%_res_val%" "%_ln%"
	if %_categ_num% LEQ %_log_lvl% call :echo_res_val "%_res_val%" "%_ln%"
) else (
	rem иначе просто выводим значение ресурса
	call :echo_res_val "%_res_val%" "%_ln%"
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Выводит значение ресурса (строкового)
rem ---------------------------------------------
:echo_res_val _res_val _ln
setlocal
set _res_val=%~1
set _ln=%~2

rem выполняем заданное кол-во переводов строк до вывода значения ресурса
for /l %%i in (1,1,%before_echo_cnt%) do echo.
rem формируем заданное кол-во отступов вправо
for /l %%i in (1,1,%right_shift_cnt%) do set "l_spaces=!l_spaces! "
rem если определена последовательность вывода, то выводим значение ресурса согласно ей
if defined g_res_output_cnt (
	1>nul chcp %code_page%
	for /l %%j in (0,1,%g_res_output_cnt%) do (
		if defined g_res_output[%%j]#Part (
			call :set_res_color !g_res_output[%%j]#Color!
			set l_part=!g_res_output[%%j]#Part!
			call :get_end_space %%j
			rem для вывода круглых скобок echo должны быть на отдельных строках
			if %right_shift_cnt% EQU 0 (
				echo | set /p "dummyName=!l_part!"
			) else (
				if %%j EQU 0 (
					echo | set /p "dummyName=%BS%!l_spaces!!l_part!!end_space!"
				) else (
					echo | set /p "dummyName=!l_part!!end_space!"
				)
			)
		)
	)
	if /i "%_ln%" EQU "%VL_TRUE%" echo.
) else (
	rem  иначе - выводим значение ресурса
	if /i "%p_res_val_empty%" EQU "%VL_TRUE%" (
		rem если значение ресурса отсутствует
		if /i "%_ln%" EQU "%VL_TRUE%" echo.
	) else (
		1>nul chcp %code_page%
		rem  если определено значение ресурса, то учитываем отсутуп справа и перевод строки
		rem для вывода круглых скобок echo должны быть на отдельных строках
		if %right_shift_cnt% EQU 0 (
			if /i "%_ln%" EQU "%VL_TRUE%" (
				echo %_res_val%
			) else (
				echo | set /p "dummyName=%_res_val%"
			)
		) else (
			if /i "%_ln%" EQU "%VL_TRUE%" (
				echo !l_spaces!%_res_val%
			) else (
				echo | set /p "dummyName=%BS%!l_spaces!%_res_val%"
			)
		)
rem 1>&2 - для ошибки		
	)
)
rem выполняем заданное кол-во переводов строк после вывода значения ресурса
for /l %%i in (1,1,%after_echo_cnt%) do echo.
endlocal & exit /b 0

rem ---------------------------------------------
rem Возвращает при необходимости заключительный пробел
rem ---------------------------------------------
:get_end_space _cur_idx
setlocal
set _proc_name=%~0
set _cur_idx=%~1

set /a l_next_id=%_cur_idx%+1
if not defined g_res_output[%l_next_id%]#Part endlocal & set "%_proc_name:~5%=" & exit /b 0

rem echo %l_next_id% "!g_res_output[%l_next_id%]#Part!"
if "!g_res_output[%l_next_id%]#Part:~0,1!" EQU " " set "l_space= "

endlocal & set %_proc_name:~5%=%l_space%
exit /b 0

rem ---------------------------------------------
rem Устанавливает заданный цвет символов выводимой строки
rem ---------------------------------------------
:set_res_color _color
setlocal
set _color=%~1

if /i "%_color%" EQU "" (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
) else if /i "%_color%" EQU "08" (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
) else if /i "%_color%" EQU "09" (
	rem ChangeColor 9 0
	%ChangeColor_9_0%
) else if /i "%_color%" EQU "0A" (
	rem ChangeColor 10 0
	%ChangeColor_10_0%
) else if /i "%_color%" EQU "0B" (
	rem ChangeColor 11 0
	%ChangeColor_11_0%
) else if /i "%_color%" EQU "0C" (
	rem ChangeColor 12 0
	%ChangeColor_12_0%
) else if /i "%_color%" EQU "0D" (
	rem ChangeColor 13 0
	%ChangeColor_13_0%
) else if /i "%_color%" EQU "0E" (
	rem ChangeColor 14 0
	%ChangeColor_14_0%
) else if /i "%_color%" EQU "0F" (
	rem ChangeColor 15 0
	%ChangeColor_15_0%
) else if /i "%_color%" EQU "AA" (
	rem ChangeColor 10 10
	%ChangeColor_10_10%
) else if /i "%_color%" EQU "CC" (
	rem ChangeColor 12 12
	%ChangeColor_12_12%
) else (
	rem ChangeColor 8 0
	%ChangeColor_8_0%
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Определяет путь и праметры утилиты изменения цвета
rem ---------------------------------------------
:chgcolor_setup _chgcolor_dir
set _chgcolor_dir=%~1
if [%_chgcolor_dir:~-1%] EQU [%DIR_SEP%] set _chgcolor_dir=%_chgcolor_dir:~0,-1%
if not defined chgcolor_path (
	if exist "%b2eincfilepath%" (
		set chgcolor_path=%b2eincfilepath%chgcolor.exe
	) else (
		if not exist "%_chgcolor_dir%%DIR_SEP%chgcolor.exe" exit /b 1
		set chgcolor_path=%_chgcolor_dir%%DIR_SEP%chgcolor.exe
	)
	if defined chgcolor_path (
		set ChangeColor_8_0="!chgcolor_path!" 08
		set ChangeColor_9_0="!chgcolor_path!" 09
		set ChangeColor_10_0="!chgcolor_path!" 0A
		set ChangeColor_11_0="!chgcolor_path!" 0B
		set ChangeColor_12_0="!chgcolor_path!" 0C
		set ChangeColor_13_0="!chgcolor_path!" 0D
		set ChangeColor_14_0="!chgcolor_path!" 0E
		set ChangeColor_15_0="!chgcolor_path!" 0F
		set ChangeColor_10_10="!chgcolor_path!" AA
		set ChangeColor_12_12="!chgcolor_path!" CC
	)
)
exit /b 0

rem ---------------------------------------------
rem Устанавливает все необходимые параметры
rem и ресурсы для работы скрипта
rem ---------------------------------------------
:echo_res_setup %*
rem УСТАНОВКА И ОПРЕДЕЛЕНИЕ ЗНАЧЕНИЙ ПО УМОЛЧАНИЮ:
rem цвет выводимого ресурса
set DEF_RES_COLOR=08
rem Категории ресурсов:
rem вывод значения ресурса только в файл
set CTG_FILE=FILE
rem вывод значения ресурса на экран/в файл
set CTG_CON=CON
rem ресурс-ошибка
set CTG_ERR=ERR
rem ресурс-предупреждение
set CTG_WRN=WRN
rem ресурс-информация
set CTG_INF=INF
rem ресурс-отладка
set CTG_FINE=FINE

rem идентификаторы подстановочных переменных
set V_SYMB=V

rem СБРОС ГЛОБАЛЬНЫХ ПЕРЕМЕННЫХ:
set res_val=
set res_categ=
set categ_num=
set categ_name=

rem РАЗБОР ПАРАМЕТРОВ ЗАПУСКА:
set echo_res_param_defs="-sh,script_hdr,%g_script_header%;-cm,p_cmd;-rf,res_path,%g_res_file%;-ri,p_res_id;-rv,res_val,~,p_res_val_empty;-rc,res_color,%DEF_RES_COLOR%;-rl,res_categ;-v,p_val_,~,~,values_cnt;-vc,p_val_color;-c,p_val_color_,~,~,colors_cnt;-ln,ln,%VL_TRUE%;-rs,right_shift_cnt,0;-be,before_echo_cnt,0;-ae,after_echo_cnt,0;-lf,log_path,%g_log_file%;-ll,log_lvl,%g_log_level%;-it,ignore_test_exec_mode,%VL_FALSE%;-cp,code_page,1251"
call :parse_params %~0 %echo_res_param_defs% %*
rem ошибка разбора определений параметров
rem if ERRORLEVEL 2 set p_def_prm_err=%VL_TRUE%
rem вывод справки
if ERRORLEVEL 1 call :echo_res_help & endlocal & exit /b 0
if /i "%EXEC_MODE%" EQU "%EM_DBG%" call :print_params %~0

rem При отсутствии заданных значений, устанавливаем по умолчанию
if not defined log_lvl set log_lvl=%DEF_LOG_LEVEL%
rem определяем номер категории ресурса
if defined res_categ (
	set categ_num=%res_categ:~0,1%
	set categ_name=%res_categ:~1%
)
rem определяем путь и праметры утилиты изменения цвета
call :chgcolor_setup "%CUR_DIR%"
exit /b 0

rem ---------------------------------------------
rem Проверяет установку всех необходимых параметров
rem и ресурсов скрипта
rem ---------------------------------------------
:echo_res_check_setup
setlocal
rem КОНТРОЛЬ:
rem отсутствие ИД ресурса или файла ресурсов
if not defined p_res_id if not defined res_val if /i "%p_res_val_empty%" NEQ "%VL_TRUE%" (
	set l_err_msg=ERR -1: Не задано ни ИД ресурса, ни его значение. Укажите, пожалуйста, корректный ИД ресурса или его значение.
	rem если не только вывод в файл
	if /i "%categ_name%" NEQ "%CTG_FILE%" (
		rem ChangeColor 12 0
		%ChangeColor_12_0%
		1>nul chcp %code_page% & echo !l_err_msg!
		call :echo_res_help
	) else (
		call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
	)
	endlocal & exit /b 1
)
if defined p_res_id if not exist "%res_path%" (
	set l_err_msg=ERR -1: Для ресурса [ИД=%p_res_id%] не найден ресурсный файл "%res_path%". Проверьте, пожалуйста, его наличие.
	rem если не только вывод в файл
	if /i "%categ_name%" NEQ "%CTG_FILE%" (
		rem ChangeColor 12 0
		%ChangeColor_12_0%
		1>nul chcp %code_page% & echo !l_err_msg!
		call :echo_res_help
	) else (
		call :echo_log "%log_path%" "!l_err_msg!" "%categ_num%" "%log_lvl%" "%script_hdr%"
	)
	endlocal & exit /b 1
)
endlocal & exit /b 0

rem ---------------------------------------------
rem Формат запуска утилиты
rem ---------------------------------------------
:echo_res_help
setlocal
1>nul chcp %code_page%
echo.
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo Victory BIS: Resource module for Windows 7/10 v.{Current_Version}. {Copyright} {Current_Date}
rem ChangeColor 8 0 
%ChangeColor_8_0%
echo Формат запуска утилиты:
rem ChangeColor 15 0 
%ChangeColor_15_0%
echo %g_script_name% [^<ключи^>...]
echo.
rem ChangeColor 8 0
%ChangeColor_8_0%
echo Ключи:
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -sh"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :заголовок логгируемой программы (не обязательно). Можно в вызывающем сценарии определить переменную g_script_header
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:путь к файлу ресурсов (не обязательно, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=если в вызывающем сценарии определить переменную g_res_file"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ri"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:идентификатор ресурса (не обязательно, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=если указан ключ -rv"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rv"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:значение ресурса (не обязательно, "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=если указан ключ -ri"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo )
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rc"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :цвет символов выводимого ресурса (не обязательно). Задаётся в шестнадцатиричной системе [08, 09, 0A, 0B, 0C, 0D, 0E, 0F]
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -rl"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :уровень логгирования ресурса (не обязательно). Возможны следуюшие значения [0FILE - вывод значения ресурса только в файл, 1CON - вывод значения ресурса на экран/в файл, 2ERR - ресурс-ошибка, 3WRN - ресурс-предупреждение, 4INF - ресурс-информация, 5FINE - ресурс-отладка]
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v1"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 1 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v2"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 2 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v3"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 3 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -v4"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :переменная подстановки 4 (не обязательно) - используется в значении ресурса
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -lf"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo :путь к файлу лога (не обязательно). Можно в вызывающем сценарии определить переменную g_log_file
rem ChangeColor 11 0
%ChangeColor_11_0%
echo | set /p "dummyName=   -ll"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo | set /p "dummyName=:уровень логгирования (по умолчанию "
rem ChangeColor 15 0
%ChangeColor_15_0%
echo | set /p "dummyName=%DEF_LOG_LEVEL%"
rem ChangeColor 8 0
%ChangeColor_8_0%
echo ). Можно в вызывающем сценарии определить переменную g_log_level [0 - сообщения в файл, 1 - сообщения на экран, 2 - ошибки, 3 - предупреждения, 4 - информация, 5 - отладка]
echo.
endlocal & exit /b 0
rem ---------------- EOF echo.cmd ----------------
rem {Copyright}
rem {License}
rem Сценарий работы с параметрами процедур и других сценариев

rem ---------------------------------------------
rem Удаляет ведущие и конечные пробелы
rem ---------------------------------------------
:trim
SET %2=%1
GOTO :EOF

rem ---------------------------------------------
rem Конвертирует слеши в обратные слеши и наоборот
rem согдасно заданному направлению (win|nix)
rem необходимо для некоторых windows-команд
rem ---------------------------------------------
:convert_slashes
setlocal
set _direction=%~1
set _var=%~2

if /i "%_direction%" EQU "%CSD_WIN%" (
	set _var=!_var:/=\!
) else (
	if /i "%_direction%" EQU "%CSD_NIX%" set _var=!_var:\=/!
)
endlocal & set "%3=%_var%"
exit /b 0

rem ---------------------------------------------
rem Возвращает длину строки
rem ---------------------------------------------
:len
setlocal enabledelayedexpansion&set l=0&set str=%~1
:len_loop
set x=!str:~%l%,1!&if not defined x (endlocal&set "%~2=%l%"&exit /b 0)
set /a l+=1&goto :len_loop

rem ---------------------------------------------
rem Конвертирует регистр (верхний/нижний) символов 
rem строки
rem ---------------------------------------------
:convert_case _case_mark _src_str conv_str
setlocal
Set _case_mark=%~1
Set _src_str=%~2

if /i "%_case_mark%" EQU "%CM_UPPER%" (
	CALL :UCase "%_src_str%"
	call :echo -ri:CaseConvert -v1:"%_src_str%" -v2:"%_case_mark%" -v3:"!UCase!"
	set l_conv_str=!UCase!
) else if /i "%_case_mark%" EQU "%CM_LOWER%" (
	CALL :LCase "%_src_str%"
	call :echo -ri:CaseConvert -v1:"%_src_str%" -v2:"%_case_mark%" -v3:"!LCase!"
	set l_conv_str=!LCase!
) else (
	call :echo -ri:CaseMarkUndefError
	rem call :exec_format & endlocal & exit /b 1
)
endlocal & set "%3=%l_conv_str%"
exit /b 0

rem ---------------------------------------------
rem Конвертирует регистр первого символа слова
rem в прописной
rem ---------------------------------------------
:capital_case _src_str conv_str
setlocal
Set _src_str=%~1

endlocal & set "%2=%l_conv_str%"
exit /b 0

rem ==========================================================================
rem Функции LCase() и UCase()
rem http://www.robvanderwoude.com/battech_convertcase.php
rem ==========================================================================
:LCase
:UCase
:: Converts to upper/lower case variable contents
:: Syntax: CALL :UCase _VAR1 _VAR2
:: Syntax: CALL :LCase _VAR1 _VAR2
:: _VAR1 = Variable NAME whose VALUE is to be converted to upper/lower case
:: _VAR2 = NAME of variable to hold the converted value
:: Note: Use variable NAMES in the CALL, not values (pass "by reference")
    setlocal enableextensions enabledelayedexpansion

	SET _UCase=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z А Б В Г Д Е Ё Ж З И Й К Л М Н О П Р С Т У Ф Х Ц Ч Ш Щ Ъ Ы Ь Э Ю Я
	SET _LCase=a b c d e f g h i j k l m n o p q r s t u v w x y z а б в г д е ё ж з и й к л м н о п р с т у ф х ц ч ш щ ъ ы ь э ю я
	SET _Lib_UCase_Tmp=%~1
	IF /I "%~0"==":UCase" SET _Abet=%_UCase%
	IF /I "%~0"==":LCase" SET _Abet=%_LCase%
	FOR %%Z IN (%_Abet%) DO SET _Lib_UCase_Tmp=!_Lib_UCase_Tmp:%%Z=%%Z!
	set sProcName=%~0
    	endlocal & set %sProcName:~1%=%_Lib_UCase_Tmp%
	rem SET %2=%_Lib_UCase_Tmp%
exit /b 0

rem ---------------- EOF strings.cmd ----------------
