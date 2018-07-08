Feidee Utils
============
[![Build Status](https://travis-ci.org/muyiliqing/feidee_utils.svg?branch=master)](https://travis-ci.org/muyiliqing/feidee_utils)

Free user data from [Feidee](http://www.feidee.com) private backups (.kbf).

Feidee and the KBF Format
-----------
[Feidee MyMoney](http://www.feidee.com/money/) is a set of book-keeping software
popular in China. It includes Android, iOS, web apps and several pieces of
desktop software. The Android and iOS apps produces backup in kbf format.

A kbf file is in fact a zip file contains a modified SQLite database and other
attachments, such as photos. The first 16 bits of the SQLite database is
modified so that it could not be read directly by SQLite. The database itself is
NOT encrypted. Almost all useful information is in the SQLite database.

Install
---------
```bash
gem install feidee_utils
```

Usage
----------
A set of ActiveRecord-like classes are provided to access the information in the
backup. See the quick example below.

```ruby
require 'feidee_utils'

kbf = FeideeUtils::Kbf.open_file(path_to_kbf_file)
database = kbf.db
all_accounts = database.ledger::Account.all
all_transactions = database.ledger::Transaction.all
```

For more examples see ```examples/``` (To be added).

Supported Entities
-----------------

*  Account
*  Transaction
*  AccountGroup
*  Category

Chinese Characters
-----------------

The database contains many Chinese characters such as builtin category names.
Some of the characters are also included in tests. The gem is developed under
OSX so presumably the gem should work fine in Unix-like environments with
Unicode/UTF8 or whatever the encoding is.

Why not ActiveRecord
----------------
Sometimes we have to compare the content of two backups and must open them at
the same time. Only one database can be opened using ActiveRecord. It is not
designed to be used in such a way.

Why Feidee Utils at all
-----------
Originally the Feidee Android and iOS app let users export their personal data
recorded by the app. Since some version last year (2014), the export
functionality is removed from the app and user data is trapped inside Feidee's
private system forever. The uses may pay to get pro version, or upload their
data to Feidee's server in order to export.

As a user of Feidee MyMoney, I'm truelly grateful that such great apps are
available free of charge. However I also believe that users' data belongs to
users and should be controlled by its owner. Thus I decided to build the utils
to help Feidee MyMoney users access their own data.

Disclaimer
---------
Use at your own risk. Study purpose only. Please do NOT use for any illegal
purpose. For details see MIT-LICENSE in the repo.

This software DOES NOT involve any kind of jail break, reverse engineering or
crack of any Feidee's proprietary software or app.

The trademark Feidee, Feidee MyMoney, kbf file format and database design are
intellecture properties of Feidee, or whoever the owners are.
