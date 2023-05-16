.PHONY: resume
resume:
	pdflatex documents/resume.tex
	mv resume.pdf static/
