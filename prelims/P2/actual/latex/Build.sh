#!/bin/sh

# Tex this mofo -
pdflatex $1.tex
bibtex $1
pdflatex $1.tex
pdflatex $1.tex

# Make the pdf -
#dvipdfm -p "letter" $1.dvi
