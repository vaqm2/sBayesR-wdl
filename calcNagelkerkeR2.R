#!/usr/bin/env Rscript

require(dplyr)
require(fmsb)

args        = commandArgs(trailingOnly = F)
fileOfFiles = args[1]
prefix      = args[2]
out         = data.frame("ScoreFile", "VarianceExplained")

fileStream = file(fileOfFiles, "r")
{
  scoreFile = readLines(fileStream, n = 1)
  if(length(scoreFile) == 0)
  {
    break
  }
  scores = read.table(scoreFile, header = TRUE)
  logReg = glm(data = scores, PHENO ~ SCORE)
  r2     = NagelkerkeR2(logReg)
  rbind(out, cbind(scoreFile, r2))
}
close(fileStream)

write.table(out, paste(prefix, ".VarianceExplained.txt", row.names = F, quote = F))
