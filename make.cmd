rgbasm -omain.o main.s
rgblink -p00 -omain.gb main.o
rgbfix -v -m00 -p00 -tMain Main.gb 
