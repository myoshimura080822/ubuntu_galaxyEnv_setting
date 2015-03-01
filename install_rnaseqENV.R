is.installed <- function(mypkg){
    is.element(mypkg, installed.packages()[,1])
}

if (!is.installed("dplyr")){
    install.packages('lazyeval', repos="http://cran.rstudio.com/")
    install.packages('dplyr', repos="http://cran.rstudio.com/")
	install.packages('plyr', repos="http://cran.rstudio.com/")
	install.packages('tidyr', repos="http://cran.rstudio.com/")
	install.packages('stringr', repos="http://cran.rstudio.com/")
}

if (!is.installed("Mus.musculus")){
	source("http://bioconductor.org/biocLite.R")
	biocLite("Mus.musculus")
	biocLite("limma")
	biocLite("edgeR")
}
