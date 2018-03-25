gitbook:
	rm -r docs
	Rscript --quiet _render.R "bookdown::gitbook"
	mv widgets docs/.
all:
	Rscript --quiet _render.R
