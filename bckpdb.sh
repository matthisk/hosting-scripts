#!/bin/bash
# Backup databse v1.0
# Author: Matthisk Heimensen
#
# This script backups a database

DUMP_DIR=""
FILE_NAME=""

NO_ARGS=0
E_OPTERROR=85

if [ $# -eq "$NO_ARGS" ]; then                       # Script invoked with no command-line args
    echo "Usage: `basename $0` options (-upfh)"
    exit $E_OPTERROR                                # Exit and explain usage
fi

usage()
{
    echo "Usage: $0 [OPTIONS]">&2
    echo "Backup a database to a certain location">&2
    echo "">&2
    echo "Mandatory arguments to long options are mandatory for short options too.">&2
    echo "  -n, --name=HOST  the hostname of the database we are backupping (for file naming)">&2
    echo "  -c, --cnf=CONF   where we can find the conf file with database specifics">&2
    echo "  -d, --dir=CONF   where to dump the backup of the database">&2
    echo "  -r, --rm=DAYS    remove backup files older then DAYS days">&2
}

while getopts "h?d:n:c:r:" opt; do
    case "$opt" in
        h)  usage; exit 0;;
		d)  DUMP_DIR=$OPTARG;;
        n)  NAME=$OPTARG;;
        c)  CONF=$OPTARG;;
        r)  RM_OLDER=$OPTARG;;
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

if [ -z "$NAME" ]; then
	echo "Error: you must supply a name for the dumped sql file"
	usage
	exit $E_OPTERROR
fi

if [ -z "$DUMP_DIR" ]; then
	echo "Error: you must supply a directory to dump the sql file"
	usage
	exit $E_OPTERROR
fi

# Execute the configuration file so we now have the needed variables
# This is not entirely secure, if someone tampers with the cnf file
source $CONF

if [ -z "$USER" ]; then
	echo "Error: the configuration file must include a variable USER"
	usage
	exit $E_OPTERROR
fi

if [ -z "$PASS" ]; then
	echo "Error: the configuration file must include a variable PASS"
	usage
	exit $E_OPTERROR
fi

if [ -z "$DATABASE" ]; then
	echo "Error: the configuration file must include a variable DATABASE"
	usage
	exit $E_OPTERROR
fi

DATE=`date +%F\(%T\)`

# Dump the sql
mysqldump -u $USER -p${PASS} $DATABASE > $DUMP_DIR/$NAME-$DATE.sql

# Only root can read or write to the dump directory
chmod 700 -R $DUMP_DIR

if [ -z "$RM_OLDER" ]; then
	echo "Not removing any old database backups"
else
	find $DUMP_DIR -type f -mtime +$RM_OLDER -delete
fi

exit 0