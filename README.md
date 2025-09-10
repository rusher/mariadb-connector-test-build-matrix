# MariaDB connector continuous integration matrix builder

other related project : https://github.com/mariadb-corporation/connector-ci-setup

matrix possibility:
```
{
  "name": "MariaDB 12.1 dev", // description
  "os": "ubuntu-latest"/"windows-latest"/"macos-latest" // os
  "db-type": "community"/"dev"/"enterprise"/"mysql" dev means using the latests development version.
  "db-tag": "12.1" // version
}
```
