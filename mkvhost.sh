#!/bin/bash
# Make Virtual Host v1.0
# Author: Matthisk Heimensen
#
# This script makes a virtual host and creates a directory for it.
# Optionally it can clone a git reposistory to this directory

ROOT_UID=0;         # Only users  with $UID 0 have root privileges
E_NOTROOT=87;       # Non-root exit error

replacedomain=$1;   # The domain to create a vhost for
replacevhost=$2;    # Optional subdomain to create a vhost for

AVA_DIR="/etc/apache2/sites-available";
ENA_DIR="/etc/apache2/sites-enabled";

# Run as root
if [ "$UID" -ne "$ROOT_UID" ]; then
    echo "Must be root to run this script."
    exit $E_NOTROOT;
fi

if [[ ${replacedomain} == "" ]]; then
    echo "Usage: mkvhost <replacedomain> (<replacevhost>)";
    echo "Example: mkvhost example.com www";
    echo "will create the virtual host for www.example.com";
    exit 0;
else
    if [[ ${replacevhost} == "" ]]; then
        vhost="${replacedomain}";
    else
        vhost="${replacevhost}.${replacedomain}";
    fi
fi

# Create http host
if [[ -e ${AVA_DIR}/${vhost} ]]; then
    echo "${AVA_DIR}/${vhost} already exists. Skipping.";
elif [[ -e ${ENA_DIR}/${vhost} ]]; then
    echo "${ENA_DIR}/${vhost} already exists. Skipping.";
else
    if [[ ! -e ${AVA_DIR}/template.http ]]; then
        echo "${AVA_DIR}/template.http does not exist. Cannot create ${ENA_DIR}/${vhost}.";
    else
        cat ${AVA_DIR}/template.http | sed "s/replacevhost/${vhost}/g" > ${AVA_DIR}/${vhost}
    fi
fi

# Create http ssl host
if [[ -e ${AVA_DIR}/${vhost}.ssl ]]; then
    echo "${AVA_DIR}/${vhost}.ssl already exists. Skipping.";
elif [[ -e ${ENA_DIR}/${vhost}.ssl ]]; then
    echo "${ENA_DIR}/${vhost}.ssl already exists. Skipping.";
else
    if [[ ! -e ${AVA_DIR}/template.http.ssl ]]; then
        echo "${AVA_DIR}/template.http.ssl does not exist. Cannot create ${ENA_DIR}/${vhost}.ssl.";
    else
        cat ${AVA_DIR}/template.http.ssl | sed "s/replacevhost/${vhost}/g" > ${AVA_DIR}/${vhost}.ssl
    fi
fi

bool="n";
echo -n "Should I enable ${AVA_DIR}/${vhost}? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    if [[ -e ${ENA_DIR}/${vhost} ]]; then
        echo "Host was already enabled.";
    else
        if [[ ! -e ${AVA_DIR}/${vhost} ]]; then
            echo "${AVA_DIR}/${vhost} does not exist so I cannot enable it.";
        else
            echo "Running: a2ensite ${vhost}";
            a2ensite ${vhost};
        fi
    fi
fi

bool="n";
echo -n "Should I enable ${AVA_DIR}/${vhost}.ssl? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    if [[ -e ${ENA_DIR}/${vhost}.ssl ]]; then
        echo "Host was already enabled.";
    else
        if [[ ! -e ${AVA_DIR}/${vhost}.ssl ]]; then
            echo "${AVA_DIR}/${vhost}.ssl does not exist so I cannot enable it.";
        else
            echo "Running: a2ensite ${vhost}.ssl";
            a2ensite ${vhost}.ssl;
        fi
    fi
fi

if [ -d "/var/www/{$vhost}" ]; then
    echo "Directory /var/www/${vhost} already exists, not creating it";
    # make sure everyone can read the vhost directory (otherwise apache will give a forbidden message)
    chmod 755 /var/www/${vhost}
else
    bool="n";
    echo -n "Should I create /var/www/${vhost} for you? ";
    read bool;
    if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
        if [[ -e /var/www/${vhost} ]]; then
            echo "/var/www/${vhost} already existed.";
        else
            mkdir -p /var/www/${vhost};
            # same as above apache needs to read this directory (even if it is not the htdocs dir)
            chmod -R 755 /var/www/${vhost};
        fi
    fi
fi

bool="n";
echo -n "Should I clone a git repo into /var/www/${vhost} for you? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    echo -n "Git repo location? ";
    read repo;
    git clone ${repo} /var/www/${vhost}/
    if [ -d /var/www/${vhost}/htdocs ]; then        # If the git repository has a htdocs directory, make www-data the owner
        chgrp -R devs /var/www/${vhost};
    fi
else
    if [ -d /var/www/${vhost}/htdocs ]; then
        :
    else
        mkdir /var/www/${vhost}/htdocs;
        chgrp -R devs /var/www/${vhost};
    fi
fi

bool="n";
echo -n "Should I restart Apache? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    echo "Running: service apache2 restart";
    service apache2 restart;
fi

exit 0