## Branch Protection Script for Tazama-lf and Frmscoe  with GitHub CLI Script

What This Will Do:

- Protect both dev and main branches with the rules listed below.
- Require Pull request before merging
- 2 approvals for the Pull request
- Dismiss stale PR approvals
- Require status checks to pass on Pull request
- Block merging unless conversation is resolved
- Prevent bypassing rules (admin enforcement)
- Require code owners listed as json


## Pre-requisites

- Install git locally on your computer.

- Be an admin on the `tazama-lf` and `frmscoe` github accounts.

- Ensure both `dev` and `main` branches exist in the declared repos.

- Ensure the repo list is updated by adding / removing the repo list.

- Generate a fine-grained personal access token with repo and admin:repo_hook scopes:
    Go to https://github.com/settings/tokens
    Save your token securely.

- Authentiate with the token generated above. Run `gh auth login`. The same token will be applied on the last command as an arg

- Make the script executable for both orgs at a time by running e.g `chmod +x tazama-lf/githubcli.sh`. This has to be done at least once for all folders / github accounts.

- Run the script to set the branch protection rules in the tazama-lf folder e.g `./githubcli.sh gh-token-here`