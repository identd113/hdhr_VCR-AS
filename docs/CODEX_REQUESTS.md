# Codex Request Archival Process

This repository now archives Codex request issues automatically whenever a pull
request that resolves them is merged. The automation relies on a lightweight
convention in the pull request description, so maintainers should follow the
steps below when submitting work that came from a Codex request.

## Referencing the Codex request

Include a line in the pull request description using the following format:

```
Codex Request: https://github.com/<owner>/<repository>/issues/<number>
```

You may reference more than one request by adding additional lines that follow
the same `Codex Request:` prefix. The workflow parses these URLs after the pull
request merges, closes the linked issues, and applies an `archived` label to
highlight that the request is complete.

## Optional cross-repository support

By default, the workflow uses the standard `GITHUB_TOKEN`, which can manage
issues within this repository. If your Codex requests live in a separate
repository, add a personal access token with the necessary permissions as the
`CODEX_ARCHIVE_TOKEN` repository secret. The workflow will automatically fall
back to that token when available and attempt to archive the linked requests in
that external repository as well.

## Troubleshooting

- **Label missing:** The workflow creates the `archived` label if it does not
  already exist. If label creation fails (for example, due to missing
  permissions), the issue will still close but remain unlabelled.
- **Malformed URL:** If the URL after `Codex Request:` is not a standard GitHub
  issue link, the workflow skips it. Edit the merged pull request description
  to fix the URL and re-run the workflow manually from the Actions tab.
