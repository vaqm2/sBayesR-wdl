#!/usr/bin/env groovy

/* This script merges the SNP posterior files after an sBayes R run
 * Accepts a list of files as input
 * Delivers a concatenated file as output
 */

def parseArgs = new CliBuilder
(
    usage: 'merge_posteriors.groovy -f <ListOfFiles.txt> -o <OutputPrefix>'
)

parseArgs.with
{
    h longOpt: 'help', required : false, 'Display Usage'
    f longOpt: 'file-list', type : File, args : 1, required : true, 'List of files with posterior SNP effects from sBayes'
    o longOpt: 'prefix', type: String, args : 1, required : true, 'Output Prefix'
}

def options = parseArgs.parse(args)

if (!options || options.h)
{
    return
}

def fileOfFiles      = options.f
def OutputPrefix     = options.o
def fofStream        = new File(fileOfFiles).newInputStream()
File Out             = new File(OutputPrefix + ".allChr.snpRes")
int snp_column       = 1
int a1_column        = 4
int a2_column        = 5
int a1_effect_column = 7
Out.write("SNP A1 A2 A1Effect" + "\n")

fofStream.eachLine()
{
    def sBayesOut        = it.trim().stripIndent()
    File sBayesOutStream = new File(sBayesOut).newInputStream()
    int lineNum          = 0
    sBayesOutStream.eachLine()
    {
        def line         = it.trim().stripIndent()
        def lineContents = line.split("\\s+")
        lineNum++
        if(lineNum == 1)
        {
            for(int i = 0; i <= lineContents.length(); i++)
            {
                switch (lineContents[i])
                {
                    case "Name" :
                        snp_column = i
                    case "A1" :
                        a1_column = i
                    case "A2"
                        a2_column = i
                    case "A1Effect"
                        a1_effect_column = i
                    default :
                        println "NOTE: Excluding column " + lineContents[i] + " not required for scoring"
                }
            }
        }
        else
        {
            def snp       = lineContents[snp_column]
            def a1        = lineContents[a1_column]
            def a2        = lineContents[a2_column]
            def a1_effect = lineContents[a1_effect_column]
            Out.append(snp + " ")
            Out.append(a1 + " ")
            Out.append(a2 + " ")
            Out.append(a1_effect + "\n")
        }
    }
}
