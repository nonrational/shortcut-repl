# shortcut-repl

A REPL wrapper for [Shortcut](https://www.shortcut.com/) and [Google Workspace](https://workspace.google.com/) to help product and project management.

## Summary

```
$ rake -T
rake config:check                       # Check config is valid
rake config:export                      # Export the config.yml file as a base64 encoded string
rake iteration:create_next              # Create the next iteration
rake iteration:cutover                  # Move all unfinished stories from the previous iteration to the current iteration
rake iteration:kickoff                  # Print a pipe delimited list of all epics that have work scheduled in the current iteration
rake iteration:preview                  # Preview the next handful iteration start/end dates
rake iteration:ready_sort:preview       # Preview the stories that would be sorted in the ready column in the current iteration by epic and priority
rake iteration:ready_sort:run           # Sort all the stories in the ready column in the current iteration by epic and priority
rake planning:sync_names_from_shortcut  # Fix any names in the planning sheet that don't match their epic's name
rake project_sync:run                   # Ensure that all stories with a project have the correct product area set
```

## Configuration

See `config.yml.example`

### Shortcut Credentials

Set `shortcut-api-token` in `config.yml` or `SHORTCUT_API_TOKEN` in `.env`.

### Google Workspace Credentials

1. Generate an OAuth2 Client at https://console.cloud.google.com/apis/credentials with the required scopes and permissions to access the Drive and Sheets APIs.
1. Download its JSON config to `client_secrets.json`.
1. Run `make serve` and visit http://localhost:4567 to fetch access and refresh tokens, saving them to `google_credentials.json`.
1. The refresh token will then automatically be used to refresh your credentials as necessary.

## Rake Completion via Homebrew

Tab completion for `rake` is really handy.

```sh
brew install bash bash-completion
curl -o "$(brew --prefix)/etc/bash_completion.d/rake" \
    "https://raw.githubusercontent.com/ai/rake-completion/e46866ebf5d2e0d5b8cb3f03bae6ff98f22a2899/rake"
```

## Automation via GitHub Actions

Once you've got everything configured in `config.yml`, run `rake config:export` to produce a base64'd version suitable to drop into your ENV.


