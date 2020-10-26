nextflow.enable.dsl = 2

params.foo = 'MODULE PARAMETER'

process SAY_HELLO {

    exec:
    println "\n${params.foo}\n"
}
