gitbook:
	rm -r docs
	Rscript PFP_data_prep.R
	Rscript _render.R "bookdown::gitbook"
	mv widgets docs/.

