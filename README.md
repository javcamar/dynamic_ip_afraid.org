**This script is designed to detect and update the dynamic IP on afraid.org in Linux.**

The operation is simple: it retrieves the external IP using different online services via the `curl` command,
then it fetches the registered DNS IP using some of the specified nameservers (NS).
Only if both operations are valid (i.e., no errors occurred) and the IPs differ, the script proceeds to update
one or more domains delegated to afraid.org using their corresponding tokens.

It is highly recommended to schedule the script to run automatically every 20 minutes using `crontab`.

**INSTALLATION:**
Place both files in the same directory or folder.
Configure the parameters:

* `DOM_CHEQUEO`: This variable must be set with one of the domains delegated to afraid.org.
  Example: `DOM_CHEQUEO=mydomain.mooo.com`
* `TOKENS`: Configure one domain per line. You can use just one or as many as needed.
  Each line should include the domain to update or an alias (for information purposes only)
  and the token provided by afraid.org.
* `LOG`: Specify the name of the log file without the extension (`.log` will be added automatically).
  Example: `LOG=/var/log/ipcheck`

Check the path on the next line, in my case the working path is /usr/local/bin but adapt it to your needs.
* `. /usr/local/bin/logsutils.lib`


Once configured, the script is ready to use.

Then you need to set up a `crontab` entry to run the script automatically every X minutes.
This is done with the command:

```bash
crontab -e
```

And you should add a line like the following (make sure to use the correct path to the script):

```
# m     h       dom     mon     dow     command
*/30    *       *       *       *       /usr/local/bin/check_ip.sh
```

Save and exit — and that’s it!
In this example, the check will run every 30 minutes, but you can customize this to your preference.

**If this helped you, buy me a beer! 🍺**

---


