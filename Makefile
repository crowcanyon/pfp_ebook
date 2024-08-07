gitbook:
	rm -r docs
	Rscript _render.R "bookdown::gitbook"
	mv widgets docs/.
all:
	Rscript _render.R
