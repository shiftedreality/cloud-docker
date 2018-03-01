#!/bin/bash

[ "$DEBUG" = "true" ] && set -x

#AUTH_JSON_FILE="$(composer -g config data-dir 2>/dev/null)/auth.json"
#
#if [ -f "$AUTH_JSON_FILE" ]; then
#    # Get composer auth information into an environment variable to avoid "you need
#    # to be using an interactive terminal to authenticate".
#    COMPOSER_AUTH=`cat $AUTH_JSON_FILE`
#fi

MAGENTO_COMMAND="magento-command"

composer --working-dir=$MAGENTO_ROOT install

chown -R www-data:www-data $MAGENTO_ROOT

if [ ! "$M2SETUP_INSTALL_DB" = "false" ]; then

    echo "Install Magento"

    INSTALL_COMMAND="$MAGENTO_COMMAND setup:install \
        --db-host=$M2SETUP_DB_HOST \
        --db-name=$M2SETUP_DB_NAME \
        --db-user=$M2SETUP_DB_USER \
        --db-password=$M2SETUP_DB_PASSWORD \
        --base-url=$M2SETUP_BASE_URL \
        --admin-firstname=$M2SETUP_ADMIN_FIRSTNAME \
        --admin-lastname=$M2SETUP_ADMIN_LASTNAME \
        --admin-email=$M2SETUP_ADMIN_EMAIL \
        --admin-user=$M2SETUP_ADMIN_USER \
        --admin-password=$M2SETUP_ADMIN_PASSWORD"

    # Use a separate value for secure base URL, if the variable is set
    if [ -n "$M2SETUP_SECURE_BASE_URL" ]; then
        INSTALL_COMMAND="$INSTALL_COMMAND --base-url-secure=$M2SETUP_SECURE_BASE_URL"
    fi

    # Only define a backend-frontname if the variable is set, or not empty.
    if [ -n "$M2SETUP_BACKEND_FRONTNAME" ]; then
        INSTALL_COMMAND="$INSTALL_COMMAND --backend-frontname=$M2SETUP_BACKEND_FRONTNAME"
    fi

    if [ "$M2SETUP_USE_SAMPLE_DATA" = "true" ]; then

      $MAGENTO_COMMAND sampledata:deploy
      composer --working-dir=$MAGENTO_ROOT update

      INSTALL_COMMAND="$INSTALL_COMMAND --use-sample-data"
    fi

    $INSTALL_COMMAND
    $MAGENTO_COMMAND index:reindex
    $MAGENTO_COMMAND setup:static-content:deploy

else
    echo "Skipping DB installation"
fi

echo "Fixing file permissions.."

find $MAGENTO_ROOT/pub -type f -exec chmod 664 {} \;
find $MAGENTO_ROOT/pub -type d -exec chmod 775 {} \;

chown -R www-data:www-data $MAGENTO_ROOT

echo "Installation complete"
