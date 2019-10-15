ca65 main.asm -o main.o --debug-info
ld65 main.o -o test.nes -t nes --dbgfile test.dbg
