# MariaDB connector continuous integration matrix builder

This defines the base matrix for connectors. 
The main files is [test-matrix.json](./test-matrix.json)

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
