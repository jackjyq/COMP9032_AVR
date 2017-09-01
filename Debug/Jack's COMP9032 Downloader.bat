:: Name: Jack's COMP9032 Downloader
:: Author: Jack Jiang
:: Version: v0.1.0
:: Data: 1/09/2017

@echo off
set port=COM3
set file_name=A6.hex

@title Jack's COMP9032 Downloader : %port% : %file_name%
echo Press any key to download %file_name% from %port%...
pause >nul

:start
    "%ProgramFiles(x86)%\Arduino\hardware\tools\avr\bin\avrdude.exe" -C ^
        "%ProgramFiles(x86)%\Arduino\hardware\tools\avr\etc\avrdude.conf" -c ^
        wiring -p m2560 -P %port% -b 115200 -U flash:w:%file_name%:i -D

    echo Press any key to download %file_name% from %port% again...
    pause >nul
goto start

