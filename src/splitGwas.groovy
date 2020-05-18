#!/usr/bin/env groovy

/*
- This is the starting point for the sBayesR pipeline
- This script has been updated to use lower heap space:
1. Accepts GWAS summary statisics as input
2. Checks required columns in accordance with mt-cojo format: SNP CHR A1 A2 freq b se p N
3. Splits the summary stats into files by chromosome
4. Writes a file with columns "SNP P" required for scoring with PLINK
*/

def parseArgs = new CliBuilder
(
    usage: 'splitGwas.groovy -i <inputGwas> -o <outputPrefix>'
)

parseArgs.with
{
    h longOpt: 'help', required : false, 'Display Usage'
    i longOpt: 'input', type : String, args : 1, required : true, 'Summary Stats File, Expected columns SNP CHR A1 A2 freq b se p N'
    o longOpt: 'prefix', type: String, args : 1, required : true, 'Output Prefix'
}

def options = parseArgs.parse(args)

if (!options || options.h)
{
    return
}

def SummStatsFile  = options.i
def outputPrefix   = options.o
int lineNum        = 0
int snpColumn      = 0
int chrColumn      = 1
int a1Column       = 2
int a2Column       = 3
int freqColumn     = 4
int bColumn        = 5
int seColumn       = 6
int pColumn        = 7
int nColumn        = 8
def gwasFileStream = new File(SummStatsFile).newInputStream()
File p_value_file  = new File(outputPrefix + ".pValues.txt")
p_value_file.write("SNP P" + "\n")

gwasFileStream.eachLine()
{
    lineNum++
    def line         = it.trim()
    def lineContents = line.split("\\s+")
    assert lineContents.size() >= 9 : "EXITING! Insufficient columns at line: " + line

    if(lineNum == 1) // Checking header in accordance with mt-cojo format
    {
        assert lineContents.contains("SNP") : "EXITING! Column SNP with rsId missing in header!"
        assert lineContents.contains("A1") : "EXITING! Column A1 with Effect Allele missing in header!"
        assert lineContents.contains("A2") : "EXITING! Column A2 with Non-Effect Allele missing in header!"
        assert lineContents.contains("freq") : "EXITING! Column freq with Allele Frequency missing in header!"
        assert lineContents.contains("b") : "EXITING! Column b with Beta/log(OR) missing in header!"
        assert lineContents.contains("se") : "EXITING! Column se with Standard Error missing in header!"
        assert lineContents.contains("p") : "EXITING! Column p with P-value missing in header!"
        assert lineContents.contains("N") : "EXITING! Column N with Sample size missing in header!"
        assert lineContents.contains("CHR") : "EXITING! Column CHR with Chromosome missing in header!"

        for (int i = 0; i < lineContents.size(); i++)
        {
            switch (lineContents[i])
            {
                case "CHR" :
                    chrColumn = i
                    break
                case "SNP" :
                    snpColumn = i
                    break
                case "A1" :
                    a1Column = i
                    break
                case "A2" :
                    a2Column = i
                    break
                case "freq" :
                    freqColumn = i
                    break
                case "b" :
                    bColumn = i
                    break
                case "se" :
                    seColumn = i
                    break
                case "p" :
                    pColumn = i
                    break
                case "N" :
                    nColumn = i
                    break
                default :
                    println "NOTE: Excluding column " + lineContents[i] + " not required in mt-cojo format"
                    break
            }
        }
    }
    else
    {
        def snpId      = lineContents[0]
        int chromosome = lineContents[chrColumn].toInteger()

        if (chromosome > 0 && chromosome < 23)
        {
            File outFile  = new File(outputPrefix + "_" + chromosome + ".assoc")
            if (!outFile.exists()) outFile.write("SNP A1 A2 freq b se p N\n")
            outFile.append(lineContents[snpColumn] + " ")
            outFile.append(lineContents[a1Column] + " ")
            outFile.append(lineContents[a2Column] + " ")
            outFile.append(lineContents[freqColumn] + " ")
            outFile.append(lineContents[bColumn] + " ")
            outFile.append(lineContents[seColumn] + " ")
            outFile.append(lineContents[pColumn] + " ")
            outFile.append(lineContents[nColumn])
            outFile.append("\n")
            p_value_file.append(lineContents[snpColumn] + " ")
            p_value_file.append(lineContents[pColumn] + " ")
            p_value_file.append("\n")
        }
        else
        {
            println "NOTE: Skipping non-autosomal chromosome at line: " + line
        }
    }
}

gwasFileStream.close()
