hosting-scripts
===============

Bash scripts for automating sys admin tasks

mkvhost
---

This script makes a virtual host and creates a directory for it.  
Optionally it can clone a git reposistory to this directory  
  
Usage: mkvhost <replacedomain> (<replacevhost>)  
Example: mkvhost example.com www  
will create the virtual host for www.example.com  

  
mkdb
---

This script can import a sql file into a new database  
  
Create a new database and import a sql file  
  
Mandatory arguments to long options are mandatory for short options too.  
  -f, --file=FILE  the sql file to import into the database  
  -u, --user=USER  the username to give the sql database  
  -p, --pass=PASS  the password to give the database  
  -h, --help       display this help and exit  
  --version        output version information and exit  
