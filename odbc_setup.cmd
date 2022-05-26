db2cmd -c -w -i db2 uncatalog node TCPFIWB1
db2cmd -c -w -i db2 uncatalog odbc data source EUB1DBM0
db2cmd -c -w -i db2 uncatalog db EUB1DBM0
db2cmd -c -w -i db2 uncatalog dcs db EUB1DBM0
db2cmd -c -w -i db2 catalog tcpip node TCPFIWB1 remote meub1.s390.uk.ibm.com server 447 security ssl
db2cmd -c -w -i db2 catalog db EUB1DBM0 as EUB1DBM0 at node TCPFIWB1 authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db EUB1DBM0 as EUB1DBM0 parms ',,INTERRUPT_ENABLED,,,,,,'
db2cmd -c -w -i db2 catalog user odbc data source EUB1DBM0
