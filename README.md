### Конвертация базы данных из MyISAM в InnoDB на примере сайта на Drupal
1. Перед началом работ, рекомендую сделать резервную копию базы данных
```sh
mysqldump -uuser -ppassword --default-character-set=utf8 database > dump.sql
```
или через drush
```sh
drush sql-dump > dump.sql
```
2. Далее, надо выяснить версию MySQL
```sh
mysql --version
```
3. Если версия mysql ниже чем 5.6.4, то надо проверить все таблицы на наличие индексов с типом FULLTEXT. Зайти через консоль в mysql
```sh
mysql -uuser -ppaswword
```
4. Перейти в базу данных information_schema, в которой хранится структура данных всех БД на сервере
```sh
use information_schema;
```
5. Выполнить запрос:
```sh
SELECT TABLE_SCHEMA,
TABLE_NAME FROM statistics
WHERE index_type LIKE 'FULLTEXT%';
```
6. Если такие таблицы есть, то необходимо изучить для чего создан индекс и изменить его тип, или удалить. При удалении индекса выборка по этим таблицам будет осуществляться медленнее. Если таблицы не найдены - переходим к следующему шагу
7. Перевести сайт в режим обслуживания, в файл index.php вставить:
```sh
header('HTTP/1.1 503 Service Unavailable');
header('Content-Type: text/html; charset=UTF-8');
print('Website under maintenance. Please visit website later.');
exit();
```
8. В файл /etc/mysql/my.cnf добавить строку
```sh
default-storage-engine=innodb
```
9. Остановить mysql:
```sh
/etc/init.d/mysql stop
```
10. В директории /var/lib/mysql файлы ibdata1, ib_logfile0, ib_logfile1 переместить в /tmp
11. Запустить mysql:
```sh
/etc/init.d/mysql start
```
12. Зайти в mysql и проверить типы поддерживаемых систем хранения, среди них должен быть innodb:
```sh
show engines;
```
13. Далее изменим систему хранения в таблицах. Это можно сделать вручную с каждой таблицей. Для этого в консоли mysql выполнить команду
```sh
ALTER TABLE `yourtable` ENGINE = InnoDB;
```
Но если таблиц много, то проще через скрипт.
14. Создайте файл convert.sh с содержимым:
```sh
DBUSER=user
DBPWD=password
DBNAME=db
ENGINE=innodb
for t in `echo "show tables" | mysql -u$DBUSER -p$DBPWD --batch --skip-column-names $DBNAME`; do
    mysql -u$DBUSER -p$DBPWD $DBNAME -e "ALTER TABLE \`$t\` ENGINE = $ENGINE;";
done
```
DBUSER=user - укажите имя пользователя для подключения к базе данных
DBPWD=password - укажите пароль от пользователя
DBNAME=db - укажите имя базы данных
ENGINE=innodb - укажите тип системы хранения данных. В данном случае указан тип innodb
15. Выполнить файл
```sh
sh convert.sh
```
16. По завершению конвертации, удалите из файла index.php строки, которые указали в начале.

Update
Все изменения по переходу с MyISAM на InnoDB рекомендуем делать на отдельной базе данных, чтобы не затронуть работу основного проекта.
