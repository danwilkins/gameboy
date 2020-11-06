"assembler/rgbasm.exe" -o hello.o hello.asm
"assembler/rgblink.exe" -o hello.gb hello.o
"assembler/rgbfix.exe" -v -p 0 hello.gb
REM "emulator/sameboy.exe" hello.gb
"debugger/NO$GMB.EXE" ../hello.gb