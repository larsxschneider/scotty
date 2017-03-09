## Scotty - Your GH Enterprise Technician :rocket:

Scotty is a collection of helper scripts for GitHub Enterprise administrators. 

---
:warning: **Attention: These scripts are not supported by GitHub. Use them at your own risk!** :warning:

---

### Initial Setup
Copy `ghe.config.template` to `ghe.config` and adjust it to your environment. In addition, it is recommended to setup the Git credential helper as this mechanism is used for GitHub API calls.

### General Info
There are two types of scripts. The first type are `report` scripts. These scripts query all kinds of information but they do not change anything on the GitHub Enterprise instance. The second type are `admin` scripts. These scripts perform actions and change things on your instance. Please handle the `admin` scripts with special care.

You can learn more about every script by calling it with the `-h` or `--help` parameter. In addition, most of the scripts will print what they would do in a "dry-run" mode triggered with the `-n` parameter.

### Examples

##### Investigate errors
Let's say you see a lot of `babeld` errors on your GitHub Enterprise System Health dashboard. You can run the following command to see all babeld errors aggregated by the hour:
```
./reports/babeld-errors.sh
```

If you spot an error that has a very high frequency, then you can look at the error over all available log data aggregate by day:
```
./reports/babeld-errors.sh --all --day | grep "your error"
```

This way you might see when the error frequency started to increase. You can query the auth and the exception log in the same way.

##### Find users that create too many LDAP requests
If LDAP is enabled, then HTTP(S) requests against GitHub Enterprise via username/password are expensive because every request issues an additional request against LDAP. Run this command to lists the 10 users that made the most username/password requests via HTTP(S) recently:
```
./reports/auth-http-without-token.sh --all
```

##### Attach files to a support bundle
If you want to share the chrony logs with GitHub support, then you can attached them to the support ticker 54321 with the following command:
```
./admin/support-bundle-attach.sh 54321 '/var/log/chrony/*'
```

##### Fork Open Source repositories
If you want to fork an Open Source repository to your GitHub Enterprise instance, then you can use this command:
```
./admin/oss-fork.sh --create scotty kirk,bones https://github.com/larsxschneider/scotty
```
The command will fork the repository to your common Open Source organization (defined in `ghe.config`) using the name "scotty". It will protect all upstream branches and configure them in a way that only the "fork update user" (defined in `ghe.config`) can modify them. Finally, it will grant the users "kirk" and "bones" write access.

You can update all branches of an existing fork with the upstream state with the following command:
```
./admin/oss-fork.sh --update scotty
```

##### Remove sensitive data
If you want to purge sensitive data from a repository, then you should [rewrite the history](https://help.github.com/enterprise/2.8/user/articles/removing-sensitive-data-from-a-repository/). Afterwards the data won't be easily accessible anymore but still be available on the GitHub Enterprise instance. Use the following command to purge all traces after you have rewritten the history:
```
./admin/repo-remove-sensitive-data.sh org/repo
```

### Contributions
These scripts are far from perfect. If you see ways to improve them or if you have ideas for new useful scripts, then I am happy to review your Pull Request.

### Acknowledgments
Almost all tricks used in these scripts I learned from the fine GitHub Enterprise support crew!

### License
Scotty is available under the MIT license. See the LICENSE file for more info.
