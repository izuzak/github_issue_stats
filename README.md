# GitHub Issue Stats

GitHub Issue Stats helps you collect statistics on issues and pull requests in GitHub repositories.

Built using [Octokit](https://github.com/octokit/octokit.rb), [commander](https://github.com/commander-rb/commander), [text-table](https://github.com/aptinio/text-table) and the [GitHub Search API](https://developer.github.com/v3/search/).

# Install

```
gem install github_issue_stats
```

# Usage

There are several commands, each for collecting certain types of statistics. Run this to see the list of available commands and options:

```
github_issue_stats help
```

Commands are executed like this:

```
github_issue_stats <command> [options]
```

Available commands:

* `history` - Collect stats on number of open issues over time

To see the list of options and usage examples for a specific command, run this:

```
github_issue_stats help <command>
```

There are several global options:

* `--token` - Tells `github_issue_stats` which token to use for making [authenticated](https://developer.github.com/v3/#authentication) GitHub API calls. If `--token` is not used, `github_issue_stats` will look for it in the `GITHUB_OAUTH_TOKEN` environment variable. You can create a token [here](https://github.com/settings/tokens). The token needs to have `public_repo` [scope](https://developer.github.com/v3/oauth/#scopes) if the repositories you're working with are public, or `repo` scope if the repositories you're working with are private.

* `--verbose` - Tells `github_issue_stats` to output detailed debugging information to `STDERR`.

## `History` command

The `history` allows you to collect statistics on number of open issues or pull request over time. You can scope the command to all issues or pull requests or for just specific labels, and also to a single repository or all repositories owned by a specific user or organization. Statistics are collected for a specified number of intervals of configurable length, for example 5 one-week intervals or 12 three-month intervals.

The collected statistics are shown in a table, such as this one:

|              period              | [issues](https://github.com/issues?q=user:atom is:issue is:open) | [bug](https://github.com/issues?q=user:atom label:bug is:open) | [uncaught-exception](https://github.com/issues?q=user:atom label:uncaught-exception is:open) | [enhancement](https://github.com/issues?q=user:atom label:enhancement is:open) | [pulls](https://github.com/issues?q=user:atom is:pr is:open) |
| :------------------------------: | :--------------------------------------------------------------: | :------------------------------------------------------------: | :------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------: | :----------------------------------------------------------: |
| **This week** <br>(2015-09-07)   | **3398** <br>(+22, -14)                                          | **936** <br>(+2, -2)                                           | **181** <br>(+0, -0)                                                                         | **1168** <br>(+2, -1)                                                          | **347** <br>(+18, -8)                                        |
| **Last week** <br>(2015-08-31)   | **3390** <br>(+174, -119)                                        | **936** <br>(+21, -24)                                         | **181** <br>(+6, -5)                                                                         | **1167** <br>(+15, -6)                                                         | **337** <br>(+110, -92)                                      |
| **2 weeks ago** <br>(2015-08-24) | **3335** <br>(+198, -180)                                        | **939** <br>(+30, -41)                                         | **180** <br>(+9, -5)                                                                         | **1158** <br>(+28, -15)                                                        | **319** <br>(+126, -98)                                      |
| **3 weeks ago** <br>(2015-08-17) | **3317** <br>(+185, -109)                                        | **950** <br>(+22, -9)                                          | **176** <br>(+8, -2)                                                                         | **1145** <br>(+17, -8)                                                         | **291** <br>(+70, -62)                                       |

### Options

To see the list of supported options and examples for this command, run this:

```
github_issue_stats help history
```

There are several supported options:

```
-s, --scopes x,y,z               List of scopes for which stats will be collected. A scope is
                                 a username or repo name. Example: --scopes github,rails/rails

-l, --labels [x,y,z]             List of labels for which stats will be collected for each
                                 scope. A label is an issue or pull request label, or special
                                 values 'issues' and 'pulls' representing all issues and all
                                 pull requests within the scope respectively. Default: 'issues'.
                                 Example: --labels issues,bug,pulls

-i, --interval_length [STRING]   Size of interval for which stats will be aggregated. Intervals
                                 are defined with N[hdwmy], where h is hour, d is day, w is week
                                 m is month, y is year, and N is a positive integer used as a
                                 multiplier. Default: '1w'. Example: --interval_length 4d

-n, --interval_count [INTEGER]   Number of intervals for which stats will be collected.
                                 Default: 4. Example: --interval_count 2

-o, --output_format [STRING]     Format used for output tables with collected stats. Can be
                                 'text' or 'markdown'. Default: 'text'. Example: -o markdown
```

### Examples

Here's an example where the statistics for the `atom` organization are collected, for issues, pull requests and the `bug`, `enhancement` and `uncaught-exception` labels. The interval length is set to one week, and statistics are collected for four intervals. Note: I've defined my GitHub token in the `GITHUB_OAUTH_TOKEN` so I don't need to specify it with every command.

```
github_issue_stats history --scopes atom --labels issues,bug,enhancement,pulls --interval_length 1w --interval_count 4 --output_format markdown
```

Raw markdown output from the program:

```
atom stats:

|              period              | [issues](https://github.com/issues?q=user:atom is:issue is:open) | [bug](https://github.com/issues?q=user:atom label:bug is:open) | [uncaught-exception](https://github.com/issues?q=user:atom label:uncaught-exception is:open) | [enhancement](https://github.com/issues?q=user:atom label:enhancement is:open) | [pulls](https://github.com/issues?q=user:atom is:pr is:open) |
| :------------------------------: | :--------------------------------------------------------------: | :------------------------------------------------------------: | :------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------: | :----------------------------------------------------------: |
| **This week** <br>(2015-09-07)   | **3398** <br>(+22, -14)                                          | **936** <br>(+2, -2)                                           | **181** <br>(+0, -0)                                                                         | **1168** <br>(+2, -1)                                                          | **347** <br>(+18, -8)                                        |
| **Last week** <br>(2015-08-31)   | **3390** <br>(+174, -119)                                        | **936** <br>(+21, -24)                                         | **181** <br>(+6, -5)                                                                         | **1167** <br>(+15, -6)                                                         | **337** <br>(+110, -92)                                      |
| **2 weeks ago** <br>(2015-08-24) | **3335** <br>(+198, -180)                                        | **939** <br>(+30, -41)                                         | **180** <br>(+9, -5)                                                                         | **1158** <br>(+28, -15)                                                        | **319** <br>(+126, -98)                                      |
| **3 weeks ago** <br>(2015-08-17) | **3317** <br>(+185, -109)                                        | **950** <br>(+22, -9)                                          | **176** <br>(+8, -2)                                                                         | **1145** <br>(+17, -8)                                                         | **291** <br>(+70, -62)                                       |
```

Rendered markdown output:

|              period              | [issues](https://github.com/issues?q=user:atom is:issue is:open) | [bug](https://github.com/issues?q=user:atom label:bug is:open) | [uncaught-exception](https://github.com/issues?q=user:atom label:uncaught-exception is:open) | [enhancement](https://github.com/issues?q=user:atom label:enhancement is:open) | [pulls](https://github.com/issues?q=user:atom is:pr is:open) |
| :------------------------------: | :--------------------------------------------------------------: | :------------------------------------------------------------: | :------------------------------------------------------------------------------------------: | :----------------------------------------------------------------------------: | :----------------------------------------------------------: |
| **This week** <br>(2015-09-07)   | **3398** <br>(+22, -14)                                          | **936** <br>(+2, -2)                                           | **181** <br>(+0, -0)                                                                         | **1168** <br>(+2, -1)                                                          | **347** <br>(+18, -8)                                        |
| **Last week** <br>(2015-08-31)   | **3390** <br>(+174, -119)                                        | **936** <br>(+21, -24)                                         | **181** <br>(+6, -5)                                                                         | **1167** <br>(+15, -6)                                                         | **337** <br>(+110, -92)                                      |
| **2 weeks ago** <br>(2015-08-24) | **3335** <br>(+198, -180)                                        | **939** <br>(+30, -41)                                         | **180** <br>(+9, -5)                                                                         | **1158** <br>(+28, -15)                                                        | **319** <br>(+126, -98)                                      |
| **3 weeks ago** <br>(2015-08-17) | **3317** <br>(+185, -109)                                        | **950** <br>(+22, -9)                                          | **176** <br>(+8, -2)                                                                         | **1145** <br>(+17, -8)                                                         | **291** <br>(+70, -62)                                       |

With `--output_format text`, you'd get a table like this:

```
atom stats:

+--------------------------+-------------------+----------------+--------------------+-----------------+-----------------+
|          period          |      issues       |      bug       | uncaught-exception |   enhancement   |      pulls      |
+--------------------------+-------------------+----------------+--------------------+-----------------+-----------------+
| This week (2015-09-07)   | 3398 (+22, -14)   | 936 (+2, -2)   | 181 (+0, -0)       | 1168 (+2, -1)   | 347 (+18, -8)   |
| Last week (2015-08-31)   | 3390 (+174, -119) | 936 (+21, -24) | 181 (+6, -5)       | 1167 (+15, -6)  | 337 (+110, -92) |
| 2 weeks ago (2015-08-24) | 3335 (+198, -180) | 939 (+30, -41) | 180 (+9, -5)       | 1158 (+28, -15) | 319 (+126, -98) |
| 3 weeks ago (2015-08-17) | 3317 (+185, -109) | 950 (+22, -9)  | 176 (+8, -2)       | 1145 (+17, -8)  | 291 (+70, -62)  |
+--------------------------+-------------------+----------------+--------------------+-----------------+-----------------+
```

### How does the `history` command work?

This command uses the [GitHub Search API](https://developer.github.com/v3/search/) to get the number of open or closed issues in specific intervals and uses that to compute the other statistics.

The program starts by getting the current number of open issues for a specific scope and label. It then collects the number of new issues created in the current interval, and the number of issues that were closed in the interval. Using these three numbers, the number of open issues at the beginning of the interval is computed. Finally, the computed number of issues at the beginning of the interval is taken as the number of open issues at the end of the previous interval, and the whole process is repeated until all intervals have been processed. Re-opened issues and pull requests are not taken into account, so these might cause some incorrectness in computed statistics.

Since the search API has [a low rate limit](https://developer.github.com/v3/search/#rate-limit), statistics are collected slowly and it might take a minute or two to collect everything, depending on the number of defined scopes, labels and intervals.

# Similar projects

Let me know if know of any similar projects!

* https://github.com/chillu/github-dashing
* https://github.com/StephenOTT/GitHub-Analytics
* http://www.gousios.gr/blog/ghtorrent-project-statistics/

# License

[MIT](LICENSE.txt)
