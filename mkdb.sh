#!/bin/bash
# Import a database v1.0
# Author: Matthisk Heimensen
#
# This script can import a sql file into a new database
#

NO_ARGS=0
E_OPTERROR=85

if [ $# -eq "$NO_ARGS" ]; then                       # Script invoked with no command-line args
    echo "Usage: `basename $0` options (-upfh)"
    exit $E_OPTERROR                                # Exit and explain usage
fi

usage()
{
    echo "Usage: $0 [OPTIONS]">&2
    echo "Create a new database and import a sql file">&2
    echo "">&2
    echo "Mandatory arguments to long options are mandatory for short options too.">&2
    echo "  -f, --file=FILE  the sql file to import into the database">&2
    echo "  -u, --user=USER  the username to give the sql database">&2
    echo "  -p, --pass=PASS  the password to give the database">&2
    echo "  -h, --help       display this help and exit">&2
    echo "  --version        output version information and exit">&2
}

while getopts "h?u:p:f:" opt; do
    case "$opt" in
        h)  usage; exit 0;;
        u)  USER=$OPTARG;;
        p)  PASS=$OPTARG;;
        f)  FILE=$OPTARG;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit $E_OPTERROR
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            exit $E_OPTERROR
            ;;
    esac
done

# Check if correct arguments are supplied
if [ -z "$FILE" ]; then
    echo "Error: you must specify a sql file to import using -f"
    usage
    exit $E_OPTERROR
fi

if [ -z "$USER" ]; then
    echo "Error: you must specify a username using -u"
    usage
    exit $E_OPTERROR
elif [ -e  "$FILE" ]; then
    :
else
    echo "Error: you must specify a valid file using -f"
    usage
    exit $E_OPTERROR
fi

if [ -z "$PASS" ]; then
    echo "Error: you must specify a password using -p"
    usage
    exit $E_OPTERROR
fi


# Read the database use you want to use
echo -n "What name to use for the database: ";
read dbname;

# SQL for creating a new database and user
Q1="CREATE DATABASE IF NOT EXISTS ${dbname};";
Q2="GRANT ALL ON *.* TO '${USER}'@'localhost' IDENTIFIED BY '${PASS}';";
Q3="FLUSH PRIVILEGES;";
SQL="${Q1}${Q2}${Q3}";

# Run the above SQL as root user in the database
echo "Supply mysql root password";
mysql -uroot -p -e "${SQL}";

# Run the sql from the supplied file using the newly created database
mysql -u${USER} -p${PASS} ${dbname} < ${FILE};
