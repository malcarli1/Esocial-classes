@echo off
set PATH=C:\xbase\bcc582\Bin;C:\xbase\harbour_1608\bin;%PATH%
set HB_COMPILER=bcc
hbmk2 -comp=bcc demo_retorno_lote.hbp
pause
