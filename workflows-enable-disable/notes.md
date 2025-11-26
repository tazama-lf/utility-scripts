## Enable and Disable workflow(s) Script for Tazama-lf and Frmscoe  with GitHub CLI Script

What This Will Do:

- This script will enable or disable any workflows specified automatically.

## Pre-requisites

- Install git locally on your computer.

- Be an admin on the `tazama-lf` and `frmscoe` github accounts.

- Ensure the repo list is updated by adding / removing the repo list.

- Edit workflows specified on line 15 in main.sh e.g `WORKFLOWS=("node.js.yml")` by adding the workflows you need to either enable or disable. Note that you must use workflow file names.

- Generate a fine-grained personal access token with repo and admin:repo_hook scopes:
    Go to https://github.com/settings/tokens
    Save your token securely.

- Authentiate with the token generated above. Run `gh auth login`. The same token will be applied on the last command as an arg

- Make the script executable for both orgs at a time by running e.g `chmod +x tazama-lf/githubcli.sh`. This has to be done at least once for all folders / github accounts.

- Run the script to set the branch protection rules in the tazama-lf folder e.g `./githubcli.sh gh-token-here`