version 1.0

task p_ranges {
    input {
        String p_values
        String output_prefix
    }

    command <<<
        awk -F ',' '{for(i = 1; i <= NF; i++) print $i " 0 " $i}' ${p_values}
    >>>

    output {
        File rangeList = read_string(stdout())
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
        Array [File] scores = glob("${output_prefix}.*.profile")
    }
}

task r2 {
    input {
        Array [File] scores
        String output_prefix
    }

    command {
        ./calcNagelkerkeR2.R ${write_lines(scores)} ${output_prefix}
    }

    output {
        File NagelkerkeR2 = "${output_prefix}.VarianceExplained.txt"
    }
}
