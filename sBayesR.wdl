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
        File json_ld_bins
        File json_ld_info
        File p_value_thresholds
        String out
        String code_dir
        File gctb_executable_path
        File plink_executable_path
        File groovy_executable_path
        File rscript_path
        String working_directory
    }

    Map [String, File] ld_bins = read_json(json_ld_bins)
    Map [String, File] ld_info = read_json(json_ld_info)

    call sbayes.split {
        input:
            gwas          = gwas,
            output_prefix = out,
            code_dir      = code_dir,
            groovy_path   = groovy_executable_path,
            work_dir      = working_directory,
            walltime      = "04:00:00",
            nodes         = 1,
            procs         = 1,
            memory_gb     = 8,
            errout        = "split" + "_" + out,
            job_name      = "split" + "_" + out,
    }

    scatter(chr_assoc in split.gwas_by_chr) {
        String chr       = sub(sub(sub(basename(chr_assoc), out, ""), "_", ""), "\.assoc$", "")
        String prefix    = sub(chr_assoc, "\.assoc$", "")

        call sbayes.run {
            input:
                GCTB          = gctb_executable_path,
                gwas          = chr_assoc,
                ld_bin_file   = ld_bins[chr],
                ld_info_file  = ld_info[chr],
                output_prefix = prefix,
                ld_prefix     = sub(ld_bins[chr], "\.bin$", ""),
                work_dir      = working_directory,
                walltime      = "08:00:00",
                nodes         = 1,
                procs         = 1,
                memory_gb     = 20,
                errout        = "gctb" + "_" + chr + "_" + out,
                job_name      = "gctb" + "_" + chr + "_" + out
        }
    }

    call sbayes.merge {
        input:
            code_dir       = code_dir,
            snp_posteriors = run.snp_posterior,
            output_prefix  = out,
            groovy_path    = groovy_executable_path,
            work_dir      = working_directory,
            walltime      = "04:00:00",
            nodes         = 1,
            procs         = 1,
            memory_gb     = 4,
            errout        = "merge" + "_" + out,
            job_name      = "merge" + "_" + out
    }

    call pgs.p_ranges {
        input:
            code_dir      = code_dir,
            p_values      = p_value_thresholds,
            output_prefix = out,
            work_dir      = working_directory,
            walltime      = "00:30:00",
            nodes         = 1,
            procs         = 1,
            memory_gb     = 4,
            errout        = "p_ranges" + "_" + out,
            job_name      = "p_ranges" + "_" + out
    }

    call pgs.scoring {
        input:
            PLINK         = plink_executable_path,
            rangeList     = p_ranges.rangeList,
            p_value_file  = split.p_value_file,
            snp_effects   = merge.snp_posteriors_merged,
            bed           = bed,
            bim           = bim,
            fam           = fam,
            output_prefix = out,
            work_dir      = working_directory,
            walltime      = "08:00:00",
            nodes         = 1,
            procs         = 1,
            memory_gb     = 12,
            errout        = "score" + "_" + out,
            job_name      = "score" + "_" + out
    }

    call pgs.r2 {
        input:
            code_dir      = code_dir,
            scores        = scoring.scores,
            output_prefix = out,
            Rscript       = rscript_path,
            work_dir      = working_directory,
            walltime      = "01:00:00",
            nodes         = 1,
            procs         = 1,
            memory_gb     = 8,
            errout        = "r2" + "_" + out,
            job_name      = "r2" + "_" + out
    }

    output {
        Array [File] pgs       = scoring.scores
        File VarianceExplained = r2.NagelkerkeR2
    }
}
