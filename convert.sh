DBUSER=user
DBPWD=password
DBNAME=db
ENGINE=innodb
for t in `echo "show tables" | mysql -u$DBUSER -p$DBPWD --batch --skip-column-names $DBNAME`; do
    mysql -u$DBUSER -p$DBPWD $DBNAME -e "ALTER TABLE \`$t\` ENGINE = $ENGINE;";
done

