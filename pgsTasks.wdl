version 1.0

task p_ranges {
    input {
        String p_values
        String output_prefix
    }

    command {
        bin/write_p_ranges.groovy -i ${p_values} -o ${output_prefix}
    }

    output {
        File rangeList = "${output_prefix}_p_value_thresholds.txt"
    }
}

task scoring {
    input {
        File rangeList
        File snp_effects
        File bed
        File bim
        File fam
        File p_value_file
        String output_prefix
        File PLINK
    }

    command {
        ${PLINK} --bed ${bed} \
        --bim ${bim} \
        --fam ${fam} \
        --out ${output_prefix} \
        --q-score-range ${rangeList} ${p_value_file}\
        --score ${snp_effects} 1 2 4 header
    }

    output {
        File scores = glob("${output_prefix}.*.profile")
    }
}

task r2 {
    input {
        File scores
        File pheno
        File output_prefix
    }

    command {
        ./calcNagelkerkeR2.R ${scores} ${pheno}
    }

    output {
        File NagelkerkeR2 = "${output_prefix}.VarianceExplained.txt"
    }
}
