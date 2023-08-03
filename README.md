# shortcut-repl

A REPL wrapper for `shortcut_ruby` to help automate stuff.

## Summary

```
$ rake -T
rake config:check                  # Check config is valid
rake config:export                 # Export the config.yml file as a base64 encoded string
rake iteration:create_next         # Create the next iteration
rake iteration:cutover             # Move all unfinished stories from the previous iteration to the current iteration
rake iteration:kickoff             # Print a pipe delimited list of all epics that have work scheduled in the current iteration
rake iteration:preview             # Preview the next handful iteration start/end dates
rake iteration:ready_sort:preview  # Preview the stories that would be sorted in the ready column in the current iteration by epic and priority
rake iteration:ready_sort:run      # Sort all the stories in the ready column in the current iteration by epic and priority
rake project_sync:run              # Ensure that all stories with a project have the correct product area set
```

## Configuration

See `config.yml.example`

## Automation via GitHub Actions

Once you've got everything configured in `config.yml`, run `rake config:export` to produce a base64'd version suitable to drop into your ENV.

