.PHONY: install
install:
	sudo apt install texlive-latex-base texlive-fonts-recommended texlive-fonts-extra
	brew install hugo
	pnpm install

.PHONY: serve
serve:
	@if [ -d "public" ] && [ "$$(ls -A public)" ]; then \
		pnpm pagefind --site "public" --silent; \
	fi

	@hugo server -D

.PHONY: post
post:
	hugo new --kind post content/blog/$(filter-out $@,$(MAKECMDGOALS)).md

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
