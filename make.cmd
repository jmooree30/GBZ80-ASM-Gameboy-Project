#!/bin/bash
rgbasm -omain.o main.s
rgbasm -owram.o wram.s
rgblink -p00 -omain.gb main.o wram.o
rgbfix -v -m00 -p00 -tmain main.gb 
