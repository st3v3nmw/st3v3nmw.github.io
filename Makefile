.PHONY: install
install:
	sudo apt install texlive-latex-base texlive-fonts-recommended texlive-fonts-extra
	brew install hugo

.PHONY: serve
serve:
	hugo server --disableFastRender

.PHONY: resume
resume:
	pdflatex documents/resume.tex
	mv resume.pdf static/
