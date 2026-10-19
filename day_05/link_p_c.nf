#!/usr/bin/env nextflow

process SPLITLETTERS {
    input:
    tuple val(meta), val(in_str), val(prefix)

    output:
    tuple val(meta), path("${prefix}*")

    script:
    """
    printf '%s' '${in_str}' | split -b ${meta.block_size} - ${prefix}
    """
}

process CONVERTTOUPPER {
    debug true
    publishDir 'results', mode: 'copy'

    input:
    path chunk

    output:
    path "${chunk}.upper"
    stdout

    script:
    """
    tr '[:lower:]' '[:upper:]' < ${chunk} | tee ${chunk}.upper
    echo
    """
}

workflow {
    // 1. read in samplesheet: block_size goes into the meta-map
    in_ch = channel.fromPath('samplesheet_2.csv')
        .splitCsv(header: true)
        .map { row -> [ [block_size: row.block_size as Integer], row.input_str, row.out_name ] }

    // 2. split the input string into chunks of size block_size
    split_ch = SPLITLETTERS(in_ch)

    // 3. remove the meta-map; flatten so every chunk file is its own item
    chunks_ch = split_ch.map { meta, files -> files }.flatten()

    // 4. convert the chunks to uppercase, print to stdout, save to results/
    CONVERTTOUPPER(chunks_ch)
}