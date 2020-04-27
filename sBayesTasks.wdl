version 1.0

task split {
    input {
        File gwas
        String output_prefix
    }

    command {
        ./splitGwas.groovy -i ${gwas} -o ${output_prefix}
    }

    output {
        Array [File] gwas_by_chr = glob("${output_prefix}_*.assoc")
        File p_value_file = "${output_prefix}.pValues.txt"
    }
}


task run {
    input {
        File GCTB
        File gwas
        File ld_matrix
        String output_prefix
    }

    command {
        ${GCTB} --sbayes R \
        --gwas-summary ${gwas} \
        --ldm ${ld_matrix} \
        --gamma 0.0,0.01,0.1,1 \
        --pi 0.95,0.02,0.02,0.01 \
        --burn-in 20000 \
        --out-freq 10 \
        --out ${output_prefix} \
        --exclude-mhc \
        --impute-n
    }

    output {
        File snp_posterior = "${output_prefix}.snpRes"
    }
}

task merge {
    input {
        Array [File] snp_posteriors
        String output_prefix
    }

    command {
        ./merge_posteriors.groovy -f ${write_lines(snp_posteriors)} -o ${output_prefix}
    }

    output {
        File snp_posteriors_merged = "${output_prefix}.allChr.snpRes"
    }
}
