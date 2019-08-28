#!/bin/bash
rgbasm -omain.o main.s
rgbasm -owram.o wram.s
rgbasm -ohram.o hram.s
rgblink -p00 -omain.gb main.o wram.o hram.o
rgbfix -v -m00 -p00 -tmain main.gb 
