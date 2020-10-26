# nextflow-module-pattern

This is a proposal for handling `module parameters` in a scalable way while balancing **modularity** and **customizability** of workflows. 

The design heuristic I've relied on is "Being explicit in our intention" a sensible way to design scalable and maintainable pipelines.

## CONTEXT: 

The Workflow files have the following three aspects `parameters`, `channels` and `workflows`. Since modularity is the core proposition of DSL2 - we can establish a pattern around this.



Let's take a minimal `module.nf` with a an uninitialized `params.foo` like the following:


```
process SAY_HELLO {

    exec:
    println "\n${params.foo}\n"
}

```

To use it in the workflow, we need to declare the variable(s) in the `workflow.nf` like so 


```nextflow
nextflow.enable.dsl = 2

params.foo= 'MODULE PARAM FROM WORKFLOW FILE'

include { SAY_HELLO } from "./module" 

workflow test {
    SAY_HELLO()
}

```

And upon execution, it gives us what we expect. 

```
$ nextflow run workflow.nf -entry test

MODULE PARAM FROM WORKFLOW FILE
```


## PROBLEM-1: 

The above `bare minimum module` pattern, only permits us to use the parameters in the `workflow` files and as a results  modules can't be developed and tested in isolation.

## SOLUTION-1:

This can be simply resolved by using `module-level-parameters` with default values, like so:

```nextflow
nextflow.enable.dsl = 2

params.foo = 'MODULE PARAMETER'

process SAY_HELLO {

    exec:
    println "\n${params.foo}\n"
}

workflow test {
    SAY_HELLO()
}


```


The above format for defining modules allows us 
- to initialize the module-level parameter with sensible default
- test each module by itself since it becomes a DSL2 module (as in DSL2 modules can contain (un)named workflows)

```nextflow
$ nextflow run module.nf -entry test

```

- import this module in a worflow without worrying about the parameter

```nextflow

include { SAY_HELLO } from "./module"

workflow test {
    SAY_HELLO()
}
```



And upon execution it prints the value of `foo` from the workflow file.


```
$ nextflow run workflow.nf -entry test

MODULE PARAMETER
```



**NOTE**: We can override the module-level parameter, by shadowing it at the workflow level parameter.

```nextflow

nextflow.enable.dsl = 2

// NOTE: The parameter assignent needs to be BEFORE including the module 
params.foo= 'MODULE PARAM FROM WORKFLOW FILE'


include { SAY_HELLO } from "./module"

workflow test {
    SAY_HELLO()
}

```


## PROBLEM-2: 


When we have multiple workflows and imported modules, with their own unique parameters - it becomes problematic to know which parameter belongs to which process/workflow?



```nextflow


nextflow.enable.dsl = 2

params.foo= 'MODULE PARAM FOR FOO FROM WORKFLOW FILE'
params.bar= 'MODULE PARAM FOR BAR FROM WORKFLOW FILE'

include { SAY_HELLO } from "./module"
include { SAY_BYE } from "./module"

workflow test {
    SAY_HELLO()
    SAY_BYE()

}

```


The above situation 

### PROPOSED SOLUTION:


