nextflow.enable.dsl = 2

params.SAY_HELLO = [
        foo: 'MODULE PARAM FROM WORKFLOW FILE'
]

// We rely on Groovy's map-spread operator to soft-override for the module level parameters.
include { SAY_HELLO } from "./module" addParams(*:params.SAY_HELLO)

workflow test {
    SAY_HELLO()
}
