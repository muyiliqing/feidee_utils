Feidee Utils
============

Free users' data from [Feidee](http://www.feidee.com) private backups (.kbf).

Feidee And The KBF Format
-----------
[Feidee MyMoney](http://www.feidee.com/money/) is a set of popular book-keeping software in China. It includes Android, iOS, web apps and several desktop software. The Android and iOS apps produces backup in kbf format.

A kbf file is in fact a zip file contains a modified SQLite database and other attachments, such as photos.
The first 16 bits of the SQLite database is modified so that it could not be read directly by SQLite.
The database itself is NOT encrypted. Almost all useful information is in the SQLite database.

Usage
----------
A set of ActiveRecord-like classes are provided to access the information in the backup. See the quick example below.

```ruby
require 'feidee_utils'

kbf = FeideeUtils::Kbf.open_file(path_to_kbf_file)
database = kbf.sqlite_db
all_accounts = database.namespaced::Accounts.all
all_transactions = database.namespaced::Transactions.all
```

For more examples see ```examples/``` (To be added).

Why not ActiveRecord
----------------
Sometimes we have to compare the content of two backups and must open them at the same time.
Only one database can be opened using ActiveRecord. It is not designed to be used in such a way.

Why Feidee Utils At All
-----------
Originally the Feidee Android and iOS app let users export their personal data recorded by the app.
Since some version last year, the functionality is removed from the app and user data is trapped inside Feidee's private system forever. The uses may pay to get pro version, or upload their data to Feidee's server in order to export.

As a user of Feidee MyMoney, I'm truelly grateful that such great apps are available free of charge. However I also believe that users' data belongs to users and should be controlled by its owner. Thus I decided to build the utils to help Feidee MyMoney users access their own data.

Disclaimer
---------
Use at your own risk. Study purpose only. Please do NOT use for any illegal purpose. For details see MIT-LICENSE in the repo.

This software DOES NOT involve any kind of jail break, reverse engineering or crack of any Feidee's software or app.

The trademark Feidee, Feidee MyMoney, kbf file format and database design are intellecture properties of Feidee, or whoever the owners are.
