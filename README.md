# Docker Owncloud installation on ARM

This guide assumes that you have a folder /home/owncloud that stores your files on the host and not within the docker
image


## Install from scratch

Follow those simple steps: 

1. Clone the git repo
    ```bash
    git clone https://github.com/patklaey/docker-owncloud
    cd docker-owncloud
    ```
1. Modify the ```.env``` file to change passwords
    ```bash
    vi .env
    ```
1. Start up the containers
    ```bash
    docker-compose up -d
    ```
Congrats, you're done, that was really easy right? 

## Install from existing Owncloud installation

If there is an already existing installation, make sure you have your files copied (or mounted) to /home/owncloud, then
follow those steps:

1. Clone the git repo
    ```bash
    git clone https://github.com/patklaey/docker-owncloud
    cd docker-owncloud
    ```
1. Modify the ```.env``` file to change passwords
    ```bash
    vi .env
    ```
1. Start up the containers
    ```bash
    docker-compose up -d
    ```
1. Copy the database backup into the db container
    ```bash
    docker cp /path/to/backup/owncloud-utf.sql owncloud-db:/root
    ```
1. Import the database backup
    ```bash
    source .env
    docker exec owncloud-db sh -c "mysql -u ${DB_USERNAME} --password=${DB_PASSWORD} ${DB_NAME} < /root/owncloud-utf.sql"  
    ```
1. Upgrade the database if necessary (see also [Troubleshooting](#troubleshooting) as there are some common issues with 
the upgrade)
    ```bash
    docker exec owncloud-web occ maintenance:mode --on
    docker exec owncloud-web occ upgrade
    docker exec owncloud-web occ maintenance:mode --off
    ```
    
    
### Troubleshooting

* The upgrade might fail because there are apps in the existing installation that you don't have on the new one, in case
you see the following: 
    ```
    2019-11-23T15:47:53+00:00 Repair step: Upgrade app code from the marketplace
    2019-11-23T15:47:53+00:00 Repair warning: You have incompatible or missing apps enabled that could not be found or updated via the marketplace.
    2019-11-23T15:47:53+00:00 Repair warning: Please install or update the following apps manually or disable them with:
    occ app:disable activity
    occ app:disable files_pdfviewer
    occ app:disable files_texteditor
    occ app:disable templateeditor
    ```
    Simply execute the commands listed either from within the container or from the host as follows: 
    ```bash
    docker exec owncloud-web occ app:disable activity
    docker exec owncloud-web occ app:disable files_pdfviewer
    docker exec owncloud-web occ app:disable files_texteditor
    docker exec owncloud-web occ app:disable templateeditor  
    ```
* A common problem seems to the the 
```Doctrine\DBAL\Schema\SchemaException: The table with name 'owncloud.oc_persistent_locks' already exists.``` error. 
Luckily it can be easily fixed by simply deleting that table from the database:
    ```bash
    sourec .env
    docker exec owncloud-db mysql -u ${DB_USERNAME} --password=${DB_PASSWORD} ${DB_NAME} -e "drop table oc_persistent_locks"
    ```
* Should you see 
    ![not_found](images/not_found.png)
    when accessing files, then make sure the ```'datadirectory' => '/mnt/data/files',``` in your ```config/config.php```
    matches the path specified in the ```oc_accounts``` table in the database. To solve that you have multiple options: 
    * Change the path in the database to match you ```config.php``` file
    * Change the path in the ```config.php``` file to match what's in the database
    * Create a symlink from the database path to what you have in ```config.php```
    
    There are pros and cons for each of the solutions, the easiest however might be the symlink as that won't touch the 
    the database nor the config written by the installer: 
    ```bash
    docker exec owncloud-web ln -s /mnt/data/files/ /home/owncloud
    ```