version 1.0

task p_ranges {
    input {
        File p_values
        String output_prefix
        String code_dir
        String cwd
        String walltime
        Int nodes
        Int procs
        Int memory_gb
        String err
        String out
        String job_name
    }

    command {
        perl ${code_dir}/p_ranges.pl ${p_values} ${output_prefix}
    }

    output {
        File rangeList = "${output_prefix}.rangeList.txt"
    }

    runtime {
        walltime : walltime
        cpu : procs
        memory : memory_gb
        err : err
        out : out
        job_name : job_name
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
        String cwd
        String walltime
        Int nodes
        Int procs
        Int memory_gb
        String err
        String out
        String job_name
    }

    command {
        ${PLINK} --bed ${bed} \
        --bim ${bim} \
        --fam ${fam} \
        --out ${output_prefix} \
        --q-score-range ${rangeList} ${p_value_file} min \
        --score ${snp_effects} 1 2 4 header
    }

    output {
        Array [File] scores = glob("${output_prefix}.*.sscore")
    }

    runtime {
        walltime : walltime
        cpu : procs
        memory : memory_gb
        err : err
        out : out
        job_name : job_name
    }
}

task r2 {
    input {
        String code_dir
        Array [File] scores
        String output_prefix
        File Rscript
        String cwd
        String walltime
        Int nodes
        Int procs
        Int memory_gb
        String err
        String out
        String job_name
    }

    command {
        ${Rscript} ${code_dir}/calcNagelkerkeR2.R ${write_lines(scores)} ${output_prefix}
    }

    output {
        File NagelkerkeR2 = "${output_prefix}.VarianceExplained.txt"
    }

    runtime {
        walltime : walltime
        cpu : procs
        memory : memory_gb
        err : err
        out : out
        job_name : job_name
    }
}
