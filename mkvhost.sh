#!/bin/bash
replacevhost=$2;
replacedomain=$1;
ava="/etc/apache2/sites-available";
ena="/etc/apache2/sites-enabled";

if [[ ${replacedomain} == "" ]]; then
    echo "Usage: mkvhost <replacedomain> (<replacevhost>)";
    echo "Example: mkvhost example.com www";
    echo "         will create the virtual host for www.example.com";
    exit 0;
else
    if [[ ${replacevhost} == "" ]]; then
        vhost="${replacedomain}";
    else
        vhost="${replacevhost}.${replacedomain}";
    fi
fi

# Create http host
if [[ -e ${ava}/${vhost} ]]; then
    echo "${ava}/${vhost} already exists. Skipping.";
elif [[ -e ${ena}/${vhost} ]]; then
    echo "${ena}/${vhost} already exists. Skipping.";
else
    if [[ ! -e ${ava}/template.http ]]; then
        echo "${ava}/template.http does not exist. Cannot create ${ena}/${vhost}.";
    else
        cat ${ava}/template.http | sed "s/replacevhost/${replacevhost}/g" | sed "s/replacedomain/${replacedomain}/g" > ${ava}/${vhost}
    fi
fi

# Create http ssl host
if [[ -e ${ava}/${vhost}.ssl ]]; then
    echo "${ava}/${vhost}.ssl already exists. Skipping.";
elif [[ -e ${ena}/${vhost}.ssl ]]; then
    echo "${ena}/${vhost}.ssl already exists. Skipping.";
else
    if [[ ! -e ${ava}/template.http.ssl ]]; then
        echo "${ava}/template.http.ssl does not exist. Cannot create ${ena}/${vhost}.ssl.";
    else
        cat ${ava}/template.http.ssl | sed "s/replacevhost/${replacevhost}/g" | sed "s/replacedomain/${replacedomain}/g" > ${ava}/${vhost}.ssl
    fi
fi

bool="n";
echo -n "Should I enable ${ava}/${vhost}? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    if [[ -e ${ena}/${vhost} ]]; then
        echo "Host was already enabled.";
    else
        if [[ ! -e ${ava}/${vhost} ]]; then
            echo "${ava}/${vhost} does not exist so I cannot enable it.";
        else
            echo "Running: cp ${ava}/${vhost} ${ena}/${vhost}";
            a2ensite ${vhost};
        fi
    fi
fi

bool="n";
echo -n "Should I enable ${ava}/${vhost}.ssl? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    if [[ -e ${ena}/${vhost}.ssl ]]; then
        echo "Host was already enabled.";
    else
        if [[ ! -e ${ava}/${vhost}.ssl ]]; then
            echo "${ava}/${vhost}.ssl does not exist so I cannot enable it.";
        else
            echo "Running: cp ${ava}/${vhost}.ssl ${ena}/${vhost}.ssl";
            a2ensite ${vhost}.ssl;
        fi
    fi
fi

bool="n";
echo -n "Should I create /var/www/${vhost}/htdocs for you? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    if [[ -e /var/www/${vhost}/htdocs ]]; then
        echo "/var/www/${vhost}/htdocs already existed.";
    else
        mkdir -p /var/www/${vhost}/htdocs;
        chown -R www-data /var/www/${vhost};
        chmod -R 755 /var/www/${vhost};
    fi
fi

bool="n";
echo -n "Should I clone a git repo into /var/www/${vhost}/htdocs for you? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    echo -n "Git repo location? ";
    read repo;
    git clone ${repo} /var/www/${vhost}/htdocs/
fi

bool="n";
echo -n "Should i import a database from /var/www/${vhost}/htdocs/sql/ for you? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    echo -n "Supply password for database user: ";
    read pass;
    Q1="CREATE DATABASE IF NOT EXISTS ${vhost};";
    Q2="GRANT ALL ON *.* TO 'matthisk'@'localhost' IDENTIFIED BY '${pass}';";
    Q3="FLUSH PRIVILEGES;";
    SQL="${Q1}${Q2}${Q3}";
    mysql -uroot -p -e "${SQL}";

    echo -n "Sql file name? ";
    read sqlfile;
    mysql -uroot -p${pass} ${vhost} < /var/www/${vhost}/htdocs/sql/${sqlfile};
fi


bool="n";
echo -n "Should I restart Apache? ";
read bool;
if [[ ${bool} == "y" || ${bool} == "Y" || ${bool} == "yes" || ${bool} == "YES" || ${bool} == "Yes" ]]; then
    echo "Running: service apache2 restart";
    service apache2 restart;
fi