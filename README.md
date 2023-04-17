# shortcut-repl

A REPL wrapper for `shortcut_ruby` to help automate stuff.

## Summary

```
$ rake -T
rake iteration:create_next         # Create the next iteration
rake iteration:preview             # Preview the next handful iteration start/end dates
rake iteration_ready_sort:preview  # Preview the stories that would be sorted in the ready column in the current iteration by epic and priority
rake iteration_ready_sort:run      # Sort all the stories in the ready column in the current iteration by epic and priority
rake project_sync:run              # Ensure that all stories with a project have the correct product area set
```
