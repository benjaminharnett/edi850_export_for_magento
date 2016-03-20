# edi850_export_for_magento

1. Install BusinessLogic.pm, it's a collection of utilities designed for e-commerce sites.

```
cd Business-Logic-0.01/
perl Makefile.pl
make
make test
make install
```
   
2. You can now run create850s.pl from the commandline, with the following options:

```
--host=[your database host, often localhost]
--username
--password
   
--sender=[the EDI sender, often the digits of a phone number]
--recipient=[the EDI recipient]
--destination=[the folder to place the EDI files in for pickup]
```

e.g. (with PASSWORD as env variable)

```
./create850s.pl --host=localhost --username sdfdsf --password $PASSWORD --sender=123456891 --recipient=1234567891 --destination=/home/warehouse/edi850s/
```
