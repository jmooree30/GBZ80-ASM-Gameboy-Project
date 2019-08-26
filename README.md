# GBZ80 Assembly
This project is a game in the making to run on the original Nintendo Gameboy(DMG) hardware. 


Assemble and link with [RGBASM](https://github.com/rednex/rgbds).
```
rgbasm -omain.o main.s
rgblink -p00 -omain.gb main.o
rgbfix -v -m00 -p00 -tmain main.gb 
```
