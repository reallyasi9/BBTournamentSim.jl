# b1g-bbtournament-sim

## Usage

This repository consists of two download scripts (`get-cbs-teams.jl` and `get-cbs-brackets.jl`), three parsing scripts (`parse-fivethirtyeight.jl`, `parse-cbs.jl`, and `parse-pickem.jl`), and one simulation script (`simulate.jl`). These are to be run in roughly the order they are introduced.

### `get-cbs-teams.jl`

The first download script, `get-cbs-teams.jl`, is used to download team information in JSON format from CBS using an API call, then saving that information to a local YAML file for use by other scripts. The script describes its command-line arguments if run:

```sh
$ julia --project=. get-cbs-teams.jl
required argument gender was not provided
usage: get-cbs-teams.jl [-o OUTFILE] gender
```

The `gender` argument can be either "mens" or "womens". Running this script will create a YAML file with CBS team IDs and CBS team location names. **You must manually edit the team location names to match those of FiveThirtyEight!**

### `get-cbs-brackets.jl`

The second download script, `get-cbs-brackets.jl`, is used to download picks from the CBS pool in JSON format using an API call, then saving that information to a local YAML file for use by other scripts. The script describes its command-line arguments if run:

```sh
$ julia --project=. get-cbs-brackets.jl
required argument pid was not provided
usage: get-cbs-brackets.jl [-n ENTRIES] [-o OUTFILE] pid poolid gender
                        teammap
```

The `pid` argument is the most difficult to discover: one must log in to CBS, then look at the cookies stored for `https://picks.cbssports.com` to find the `pid` cookie. The `poolid` argument can be found in the URL of the bracket pool status page. The `gender` argument is either "mens" or "womens", and the `teammap` argument is the path the the appropriate team map downloaded and edited after running the `get-cbs-teams.jl` script, above.

### `parse-fivethirtyeight.jl`

This script parses the 