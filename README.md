Scripts that Automate DevOps / Project Management Tasks

# Branch Protection Script for Tazama-lf and Frmscoe  with GitHub CLI Script

What This Will Do:

- Protect both dev and main branches with the rules listed below.

- Require Pull request before merging
- 2 approvals for the Pull request
- Dismiss stale PR approvals
- Require status checks to pass on Pull request
- Block merging unless conversation is resolved
- Prevent bypassing rules (admin enforcement)


## Pre-requisites

- Install git locally on your computer.

- Be an admin on the `tazama-lf` and `frmscoe` github accounts.

- Ensure both `dev` and `main` branches exist in the declared repos.

- Ensure the repo list is updated by adding / removing the repo list.

- Generate a fine-grained personal access token with repo and admin:repo_hook scopes:
    Go to https://github.com/settings/tokens
    Save your token securely.

- Authentiate with the token generated above. Run `gh auth login`

- Make the script executable by running `chmod +x githubcli.sh`. This has to be done at least once for all folders / github accounts.

- Run the script to set the branch protection rules with `./githubcli.sh`
