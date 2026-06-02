@echo off
setlocal

set "PATH=C:\Borland\bcc58\Bin;C:\MiniGUI\Harbour\bin\bin;%PATH%"
set "HB_COMPILER=bcc"

:: Executa a compilação enviando a saída para o filtro FINDSTR, eliminando linhas que contenham "Warning"
C:\MiniGUI\Harbour\bin\hbmk2.exe demo_classes.prg esocial_classes.prg esocial_crypto.prg -comp=bcc -lhbwin -LC:\Borland\bcc58\Lib\PSDK -lcrypt32 -ladvapi32 -q -w0 2>&1 | findstr /V /I /C:"Warning"

rem pause
endlocal