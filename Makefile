.PHONY: install
install:
	sudo apt install texlive-latex-base texlive-fonts-recommended texlive-fonts-extra
	brew install hugo
	pnpm install

.PHONY: serve
serve:
	hugo server -D

.PHONY: build
build:
	hugo --minify
	pnpm pagefind --site "public"

.PHONY: post
post:
	hugo new content/blog/$(filter-out $@,$(MAKECMDGOALS)).md

.PHONY: til
til:
	hugo new --kind til content/til/$(filter-out $@,$(MAKECMDGOALS)).md

.PHONY: resume
resume:
	pdflatex documents/resume.tex
	mv resume.pdf static/
	rm resume.aux resume.log resume.out

%:
	@:
