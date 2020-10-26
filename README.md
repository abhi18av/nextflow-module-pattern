# nextflow-module-pattern

This is a proposal for handling `module parameters` in a scalable way while balancing **modularity**, **testability** and **customizability** of workflows. 

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



And upon execution it prints the value of `foo` from the **module** file.


```
$ nextflow run workflow.nf -entry test

MODULE PARAMETER
```




## PROBLEM-2: 

How do we override the module-level parameter from a workflow?

## SOLUTION-2 

We can override the module-level parameter, by shadowing it at the workflow level.

```nextflow

nextflow.enable.dsl = 2

// NOTE: The parameter assignent needs to be BEFORE including the module 
params.foo= 'MODULE PARAM FROM WORKFLOW FILE'


include { SAY_HELLO } from "./module"

workflow test {
    SAY_HELLO()
}

```


And upon execution it prints the value of `foo` from the workflow file.


```
$ nextflow run workflow.nf -entry test

MODULE PARAM FROM WORKFLOW FILE
```




## PROBLEM-3: 


When we have multiple workflows and imported modules, with their own unique parameters, how to know which parameter belongs to which process/workflow?


## SOLUTION-3: 

We can rely on namespacing the parameters at the workflow level using the Groovy language constructs, like so:

``` nextflow
nextflow.enable.dsl = 2

// Namespaced parameters using hash-map
params.SAY_HELLO = [
        foo: 'MODULE PARAM FROM WORKFLOW FILE'
]

// Soft override of module-level parameters by workflow-level parameters using DSL2 addParams config
include { SAY_HELLO } from "./module" addParams(*:params.SAY_HELLO)

workflow test {
    SAY_HELLO()
}

```

Notice that
- we namespaced the parameters for any particular process/workflow using `params.PROCESS_NAME`  hash-map
- we rely on Groovy's `*:` map-spread operator to soft-override for the module level parameters

And upon execution it prints the value of `foo` from the workflow file.

```
$ nextflow run workflow.nf -entry test

MODULE PARAM FROM WORKFLOW FILE
```


Now, put this in contrast with the vanilla params at the workflow level and see if you can make out which parameter belongs to which process (without the string value :) ).



```nextflow


nextflow.enable.dsl = 2

params.foo= 'MODULE PARAM FOR FOO FROM WORKFLOW FILE'
params.bar= 'MODULE PARAM FOR BAR FROM WORKFLOW FILE'

include { SAY_HELLO } from "./module"
include { SAY_BYE } from "./module"

Channel.value("BYE WORLD")
       .set { say_bye_ch }

workflow test {
    SAY_HELLO()
    SAY_BYE(say_bye_ch)

}

```

Odds are that as the number of processes and parameters grow, you'd find yourself spending more time in variable management rather than workflow level testing and debugging.



## PROBLEM-4: 


How to declare the parameters in a declarative manner i.e. using a configuration file?

## SOLUTION-4: 

The nice part about the solution-3 is that, the params file (YAML in our example) becomes namespaced and clean as well. We simply need to copy and paste the `params.PROCESS_NAME` hash-map, remove the brackets, fix indents and we are done.

```yaml

SAY_HELLO :
  foo: 'MODULE PARAM FROM WORKFLOW PARAMS FILE'

```

And upon execution with the `-params-file` it prints the value of `foo` from the params file.

```
$ nextflow run workflow.nf -entry test -params-file workflow_params.yaml

MODULE PARAM FROM WORKFLOW PARAMS FILE
```

At this point, we can either choose to keep the `workflow level` parameter in the `workflow.nf` or remove it. Let's see how it'd look once the parameter declaration is removed.

```nextflow
nextflow.enable.dsl = 2

include { SAY_HELLO } from "./module" addParams(*:params.SAY_HELLO)

workflow test {
    SAY_HELLO()
}

```


## BONUS: 

How should we structure the project?


Recall that we wish to create scalable, maintainable pipelines while balancing **modularity**, **testability** and **customizability** of workflows. 

We can rely upon the time-tested software engineering practices of `unit testing`, `integration testing` and `end-to-end testing`.

- Unit testing

To develop and test modules, we can follow the tool-driven composition such as `/modules/tool_name/module_name`. 

The benefit of using a folder structure for module is that, we can populate it with test data specific to that process/module and then test it via the `nextflow run module_name.nf -entry test` workflow, assuming you have named the workflow as `test`as in `Solution-1`


``` 

modules
├── gatk
│   |
│   ├── haplotype_caller
│   │   └── haplotype_caller.nf
│   │   └── test_data
│   │   └── nextflow.config
│   │   └── test_params.yaml
│   │ 
│   └── merge_gvcfs
│       └── merge_gvcfs.nf
│       └── test_data
│       └── nextflow.config
│       └── test_params.yaml
│ 
├── utils
│   |
│   ├── my_custom_script
│       └── my_custom_script.nf
│       └── test_data
│       └── nextflow.config
│       └── test_params.yaml
```


The `test_params.yaml`, `test_data` and `nextflow.config` server the pupose of improving testability at the `module` level.


- Integration testing

Following the same philosophy, we can test the `integration` of various `modules` i.e. workflow with test data. It makes sense to follow a structure similar to the `modules` since `workflows` can also be composed together and it's better to be able to test sub-workflow fast.

```nextflow


workflows
|
├── haplotype_calling
│   └── haplotype_calling.nf
│   └── test_data
│   └── nextflow.config
│   └── test_params.yaml
```


- End-to-end testing

This kind of testing makes sense in scenarios where we have composite workflow(s). Let's assume we have a composite workflow at the `baseDir` level.


```
baseDir
└── main_workflow.nf
└── test_data
└── nextflow.config
└── test_params.yaml
|
└── modules
└── workflows

```

Please note that the workflow could even be inside the `workflows` folder, depending upon the design and optimization choices you've made for the workflow in question.
