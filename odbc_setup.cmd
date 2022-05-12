db2cmd -c -w -i db2 uncatalog node TCP0007
db2cmd -c -w -i db2 uncatalog odbc data source ICFS
db2cmd -c -w -i db2 uncatalog db ICFS
db2cmd -c -w -i db2 uncatalog dcs db ICFS
db2cmd -c -w -i db2 catalog tcpip node TCP0007 remote iccmvs2.pok.ibm.com server 5500 security ssl
db2cmd -c -w -i db2 catalog db ICFS as ICFS at node TCP0007 authentication SERVER_ENCRYPT
db2cmd -c -w -i db2 catalog dcs db ICFS as USIBMVRDP1E parms ',,INTERRUPT_ENABLED,,,,,,'
db2cmd -c -w -i db2 catalog user odbc data source ICFS
