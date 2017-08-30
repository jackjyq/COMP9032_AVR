@set COM = COM3
@set file_name = OpenMe.hex
@echo Connect your board, ready to download
@pause
"%ProgramFiles(x86)%\Arduino\hardware\tools\avr\bin\avrdude.exe" -C "%ProgramFiles(x86)%\Arduino\hardware\tools\avr\etc\avrdude.conf" -c wiring -p m2560 -P %COM% -b 115200 -U flash:w:%file_name%:i -D
@pause

