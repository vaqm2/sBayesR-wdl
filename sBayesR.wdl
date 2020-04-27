version 1.0

## This WDL implements the sBayesR polygenic scoring pipeline
##
## Inputs required: A GWAS file with header columns: SNP CHR A1 A2 frq b se p N
##                  A PLINK bfile of target genotypes
##                  A comma separated list of p-value thresholds
##                  Other parameters for gctb sbayes module
##
## Outputs: Polygenic Scores at specified p-value thresholds
##          Variance explained in the phenotype
##
## Cromwell version tested: 50
## Womtool version tested: 50
##

import "sBayesTasks.wdl" as sbayes
import "pgsTasks.wdl" as pgs

workflow sBayesR {

    String version = "1.0"

    input {
        File gwas
        File bed
        File bim
        File fam
        File pheno
        File file_of_ld_matrices_by_chr
        String p_value_thresholds
        String out
        File gctb_executable_path
        File plink_executable_path
    }

    Array [File] ld_matrices = read_lines(file_of_ld_matrices_by_chr)

    call sbayes.split {
        input:
            gwas = gwas,
            output_prefix = out
    }

    scatter(pair in zip(split.gwas_by_chr, ld_matrices)) {
        call sbayes.run {
            input:
                GCTB = gctb_executable_path,
                gwas = pair.left,
                ld_matrix = pair.right,
                output_prefix = out
        }
    }

    call sbayes.merge {
        input:
            snp_posteriors = run.snp_posterior,
            output_prefix = out
    }

    call pgs.p_ranges {
        input:
            p_values = p_value_thresholds,
            output_prefix = out
    }

    call pgs.scoring {
        input:
            PLINK = plink_executable_path,
            rangeList = p_ranges.rangeList,
            p_value_file = split.p_value_file,
            snp_effects = merge.snp_posteriors_merged,
            bed = bed,
            bim = bim,
            fam =fam,
            output_prefix = out
    }

    call pgs.r2 {
        input:
            scores = scoring.scores,
            pheno = pheno,
            output_prefix = out
    }

    output {
        File scores = scoring.scores
        File VarianceExplained = r2.NagelkerkeR2
    }
}
