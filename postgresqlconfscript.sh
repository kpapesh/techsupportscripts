#!/bin/bash


#Created -- Kaleb Papesh 10/12/2014
#Added new PostgreSQL config (still manually requires to enter changes for lines that say [CHANGETHIS]) -- Kaleb Papesh 3/15/2018

#check to see if user is root, if not inform user
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root." 1>&2
    exit 1
fi

#look for argument and handle 
case "$1" in
    #help arg
    "--help"|"-h"|"help"|"Help"|"")
echo
echo -e '\t' "PostgreSQL Conf Script Help"
echo "-------------------------------------------------"
echo "Options:"
echo -e '\t' "update"
echo -e '\t' "restore"
echo 
echo "update-- updates the postgresql.conf file with required info for Atriuum/Booktracks"
echo "restore-- restores the postgresql.conf file from the .conf.backup"
echo
echo "Example: sudo ./postgresconfscript.sh update"
echo "Example: sudo ./postgresconfscript.sh restore"
echo;;
    
    #update arg
    "update"|"Update")
#Check /etc/sysctl.conf file
echo "Checking /etc/sysctl.conf"

eofsysctl=`tail -1 /etc/sysctl.conf`

if [ ! "$eofsysctl" == "kernel.shmmax=536870912" ]; then
    echo "Please add 'kernel.shmmax=536870912' to the end of /etc/sysctl.conf file and restart the server."
    echo "Exiting script."
    exit
else
    echo "sysctl.conf file correct"
fi

#Check the current version of postgresql being used/if installed
echo "Checking current version of PostgreSQL..."

postgresver=`psql --version |grep -o '[0-9].[0-9]'`

if [ -z $postgresver ]; then
    echo "You have no PostgreSQL version installed. Exiting script."
    exit
else
    echo "Got current verison of PostgreSQL. PostgreSQL version is $postgresver."
fi

#find config file and make backup
echo "Finding config file..."
if [ ! -e /etc/postgresql/$postgresver/main/postgresql.conf ]; then
    echo "Cannot find postgresql conf file! Exiting script."
    exit
else
    echo "Found config file."
 :   #set variable to postgres path with version number
    postgresconfpath=/etc/postgresql/$postgresver/main/postgresql.conf

    #if there is no postgresql.conf.default file then make a backup
    if [ ! -e $postgresconfpath.default ]; then
	echo "Making Backup of PostgreSQL Config file..."
	cp $postgresconfpath /etc/postgresql/$postgresver/main/postgresql.conf.default
	echo "Made backup PostgreSQL Config file."
    else
	echo "Backup file already exists."
    fi
fi

#make changes to postgresql.conf file
echo "Changing PostgreSQL Config file..."

#comment out all to-be-changed instances
sed -i '/^#/!s/^listen_addresses/#listen_addresses/' $postgresconfpath
sed -i '/^#/!s/^max_connections/#max_connections/' $postgresconfpath
sed -i '/^#/!s/^shared_buffers/#shared_buffers/' $postgresconfpath
sed -i '/^#/!s/^work_mem/#work_mem/' $postgresconfpath
sed -i '/^#/!s/^maintenance_work_mem/#maintenance_work_mem/' $postgresconfpath
sed -i '/^#/!s/^vacuum_cost_delay/#vacuum_cost_delay/' $postgresconfpath
sed -i '/^#/!s/^wal_buffers/#wal_buffers/' $postgresconfpath
sed -i '/^#/!s/^checkpoint_segments/#checkpoint_segments/' $postgresconfpath
sed -i '/^#/!s/^effective_cache_size/#effective_cache_size/' $postgresconfpath
sed -i '/^#/!s/^default_statistics_target/#default_statistics_target/' $postgresconfpath
sed -i '/^#/!s/^log_line_prefix/#log_line_prefix/' $postgresconfpath
sed -i '/^#/!s/^log_timezone/#log_timezone/' $postgresconfpath
sed -i '/^#/!s/^timezone/#timezone/' $postgresconfpath

echo "Done Commenting out current instances..."

echo "for timezones search supportkb for 'PostgreSQL Timezone Settings"
echo "Example: America/Chicago"
read -p "Enter Timezone: " postgrestimezone

echo "listen_addresses = '*'			# Jason Kelley 09/16/13 (change requires restart)
port = 5432				# Jason Kelley 09/16/13 (change requires restart)
max_connections = 400			# Kaleb Papesh 02/01/18 (change requires restart)
shared_buffers = 512MB			# Kaleb Papesh 02/01/18 [CHANGETHIS](change requires restart); 1/4 mem for app & db combo; 1/2 mem for dedicated db servers; Max of 4GB; if 32-bit OS, don't set above 2 or 2.5GB
max_prepared_transactions = 0		# Jason Kelley 09/16/13 (change requires restart); can be 0 or more
work_mem = 10MB				# Kaleb Papesh 02/01/18 min 64kB
maintenance_work_mem = 256MB		# Kaleb Papesh 02/01/18
wal_buffers = 8MB      			# Kaleb Papesh 02/01/18 (change requires restart) 16MB is the useful upper-limit; increase for write-heavy systems  
vacuum_cost_delay = 50ms		# Jason Kelley 09/16/13 --0-1000 milliseconds
checkpoint_segments = 64		# Kaleb Papesh 02/01/18 --in logfile segments, min 1, 16MB each
checkpoint_timeout = 30min		# Kaleb Papesh 02/01/18
checkpoint_warning = 5min		# Kaleb Papesh 02/01/18
effective_cache_size = 1GB		# Kaleb Papesh 02/01/18 [CHANGETHIS] 1/2 total mem for app & db combo; 3/4 total mem for dedicated db servers
random_page_cost = 2   			# Jason Kelley 09/16/13
default_statistics_target = 200		# Kaleb Papesh 02/14/18 --range changed from 10-1000 when 8.4 came out. Now is 100-10000. Increased from 100 to 200
log_destination = 'stderr'  		# Jason Kelley 09/16/13
logging_collector = on			# Jason Kelley 09/16/13
log_line_prefix = '%t %d %r %h'		# Kaleb Papesh 02/14/18 t=timestamp d=db connecting to p=pid of connection r=host connecting from
log_temp_files = 0    	 		# Kaleb Papesh 02/01/18 log all temp file info
datestyle = 'iso, mdy'			# Jason Kelley 09/16/13
lc_messages = 'C' 			# Jason Kelley 09/16/13
lc_monetary = 'C'			# Jason Kelley 09/16/13
lc_numeric = 'C'			# Jason Kelley 09/16/13
lc_time = 'C'				# Jason Kelley 09/16/13
default_text_search_config = 'pg_catalog.english'      # Jason Kelley 09/16/13
log_timezone = 'America/Chicago'		       # Jason Kelley 09/16/13
timezone = 'America/Chicago'			       # Jason Kelley 09/16/13
log_min_duration_statement = 250		       # Jason Kelley 09/16/13 --statements running 250 or longer will be logged." >> $postgresconfpath

echo "Done writing to file."
echo "restarting postgres..."
/etc/init.d/postgresql stop && sleep 1
/etc/init.d/postgresql start && sleep 1

echo "Done";;

    #restore arg
    "restore"|"Restore")
#declare vars needed
postgresver=`psql --version | grep -o '[0-9].[0-9]'`
postgresconfpath=/etc/postgresql/$postgresver/main/postgresql.conf

#check for config file
echo "Finding config file..."
if [ ! -e /etc/postgresql/$postgresver/main/postgresql.conf ]; then
    echo "Cannot find postgresql conf file! Exiting script."
    exit
else
    echo "Found config file."
fi
#check if there's a .conf.default file
if [ -e $postgresconfpath.default ]; then
    echo "restoring .conf.default file"
    mv $postgresconfpath.default $postgresconfpath && sleep 1
    echo "restored .conf.default file"
else
    echo "No backup file to restore. Exiting script."
    exit
fi;;
    *)
	echo "No argument by that name."
esac
