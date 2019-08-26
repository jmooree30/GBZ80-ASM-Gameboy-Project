#!/bin/bash
rgbasm -omain.o main.s
rgblink -p00 -omain.gb main.o
rgbfix -v -m00 -p00 -tmain main.gb 
