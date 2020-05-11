version 1.0

task split {
    input {
        File gwas
        File groovy_path
        String output_prefix
        String code_dir
        String work_dir
        String walltime
        Int nodes
        Int procs
        Int memory_mb
        String err
        String out
    }

    command {
        ${groovy_path} ${code_dir}/splitGwas.groovy -i ${gwas} -o ${output_prefix}
    }

    output {
        Array [File] gwas_by_chr = glob("${output_prefix}_*.assoc")
        File p_value_file        = "${output_prefix}.pValues.txt"
    }

    runtime {
        walltime : walltime
        nodes : nodes
        cpu : procs
        memory_mb : memory_mb
        err : err
        out : out
        work_dir : work_dir
    }
}


task run {
    input {
        File GCTB
        File gwas
        File ld_bin_file
        File ld_info_file
        String output_prefix
        String ld_prefix
        String work_dir
        String walltime
        Int nodes
        Int procs
        Int memory_mb
        String err
        String out
    }

    command {
        ${GCTB} --sbayes R \
        --gwas-summary ${gwas} \
        --ldm ${ld_prefix} \
        --gamma 0.0,0.01,0.1,1 \
        --pi 0.95,0.02,0.02,0.01 \
        --burn-in 2000 \
        --out-freq 10 \
        --out ${output_prefix} \
        --exclude-mhc \
        --impute-n
    }

    output {
        File snp_posterior = "${output_prefix}.snpRes"
    }

    runtime {
        walltime : walltime
        nodes : nodes
        cpu : procs
        memory_mb : memory_mb
        err : err
        out : out
        work_dir : work_dir
    }
}

task merge {
    input {
        Array [File] snp_posteriors
        String output_prefix
        String code_dir
        File groovy_path
        String work_dir
        String walltime
        Int nodes
        Int procs
        Int memory_mb
        String err
        String out
    }

    command {
        ${groovy_path} ${code_dir}/merge_posteriors.groovy -f ${write_lines(snp_posteriors)} -o ${output_prefix}
    }

    output {
        File snp_posteriors_merged = "${output_prefix}.allChr.snpRes"
    }

    runtime {
        walltime : walltime
        nodes : nodes
        cpu : procs
        memory_mb : memory_mb
        err : err
        out : out
        work_dir : work_dir
    }
}
