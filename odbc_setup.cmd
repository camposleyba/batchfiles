db2cmd -c -w -i db2 uncatalog node TCP0001
db2cmd -c -w -i db2 uncatalog odbc data source DP1H
db2cmd -c -w -i db2 uncatalog db DP1H
db2cmd -c -w -i db2 uncatalog dcs db DP1H
db2cmd -c -w -i db2 catalog tcpip node TCP0001 remote usibmvrdp1h.ssiplex.pok.ibm.com server 5520 security ssl
db2cmd -c -w -i db2 catalog db DP1H as DP1H at node TCP0001 authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db DP1H as USIBMVRDP1H parms ',,INTERRUPT_ENABLED,,,,,,'
db2cmd -c -w -i db2 catalog user odbc data source DP1H
