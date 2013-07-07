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

# if the password is not set we generate a random password
if [ -z "$PASS" ]; then
    PASS=$(openssl rand -base64 32)
    echo "Random password generated: ${PASS}"
fi


# Read the database use you want to use
echo -n "What name to use for the database: ";
read dbname;

# SQL for creating a new database and user
Q1="CREATE DATABASE IF NOT EXISTS \`${dbname}\`;";
Q2="GRANT ALL ON *.* TO '${USER}'@'localhost' IDENTIFIED BY '${PASS}';";
Q3="FLUSH PRIVILEGES;";
SQL="${Q1}${Q2}${Q3}";

# Run the above SQL as root user in the database
echo "Supply mysql root password";
mysql -uroot -p -e "${SQL}";

# Run the sql from the supplied file using the newly created database
mysql -u${USER} -p${PASS} ${dbname} < ${FILE};

bool="n"
echo -n "Create a my.cnf one level above the directory where sql is stored? "
read bool
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    mycnf=$(dirname ${FILE})/../my.cnf
    cat /dev/null > $mycnf
    echo "USER=${USER}" >> $mycnf
    echo "PASS=${PASS}" >> $mycnf
    echo "DATABASE=${dbname}" >> $mycnf
    chmod 700 $mycnf

    bool="n"
    echo -n "Create a cron job to backup the database? "
    read bool
    if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
        TEMP=$(tempfile)
        crontab -l > $TEMP
        DIR=$(readlink -f $(dirname ${FILE})/..)
        echo "0 3 * * * dbbckp -n ${dbname} -c ${DIR}/my.cnf -d ${DIR}/sql -r 5" >> $TEMP
        crontab $TEMP
        rm $TEMP
    fi
fi

exit 0

