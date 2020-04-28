#!/usr/bin/env Rscript

require(dplyr)
require(fmsb)

args        = commandArgs(trailingOnly = TRUE)
fileOfFiles = args[1]
prefix      = args[2]
out         = paste0(prefix, ".VarianceExplained.txt")
fileStream  = file(fileOfFiles, "r")

file.create(out)
sink(out)

cat("File")
cat(" ")
cat("r2")
cat(" ")
cat("P")
cat(" ")
cat("N")
cat("\n")

while(TRUE)
{
    scoreFile = readLines(fileStream, n = 1)

    if(length(scoreFile) == 0)
    {
        break
    }
    else
    {
        scores = read.table(scoreFile, header = TRUE, comment.char = "")
        logReg = glm(data = scores, PHENO1 ~ SCORE1_AVG)
        r2     = NagelkerkeR2(logReg)

        cat(gsub("^.*/", "", scoreFile))
        cat(" ")
        cat(r2$R2)
        cat(" ")
        cat(coef(summary(logReg))[2,4])
        cat(" ")
        cat(r2$N)
        cat("\n")
    }
}

sink()
close(fileStream)
