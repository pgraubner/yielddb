# YieldDb

`yielddb` is a simple SQL-like relational algebra based on [Arel](https://github.com/rails/arel), the SQL AST manager for Ruby. The main benefit of using `yielddb` is that you can query the results of any kind of function you want to implement - in a way that you already know from [Ruby on Rails](https://github.com/rails/rails).

## Why YieldDb?

Imagine the following situation. You have a CSV-file containing the last 40 monthly payments to your Internet provider and you want to check if your provider sent you a confirmation e-mail for an expensive service you booked on top of your 20$ flat rate. In order to do this, you need to join two data sources: A CSV-file and your mail folder.

Normally, you would script some lines of `File.read()` to iterate through the CSV-file and some additional lines of code to iterate through your mail folder using `Net::IMAP.fetch()`. Then you would need to write some lines to check the condition and to merge your CSV- and mail data. Sometimes this is the right way to do it - but if you have lot of similar cases and more complex conditions, that's a lot of glue code to write.

So, how about writing a CSV-parser and an IMAP fetcher *once* and using a declarative language to query the data for *any kind of problem* involving CSV-files and mails?

Something like:

    mail = YieldDb::Table.new(:mail, Backend::ImapBackend.new('server.ip', 'myuser'))
    csv = YieldDb::Table.new(:csv, Backend::CSV.new('csv.file'))

    myquery = mail.join(csv).on( mail[:month].eq(csv[:month]) ).where( csv[:amount].gt(20).and( mail[:from].eq('service@provider.tld') ) ).to_query

    puts myquery.query &to_hash
    # {month: 'dec 2014', amount: 42.4, subject: '[Provider] Your december invoice'}
    # {month: 'dec 2014', amount: 42.4, subject: '[Provider] Your extra booking'}
    # {month: 'jan 2016', amount: 21.1, subject: '[Provider] Your january invoice'}

Did you notice that you only need a few lines of code here?

The main benefit of using `yielddb` is that you can easily execute SQL-like queries on any kind of self-implemented functions: CSV- or Excel-files, raw device input, Web Service results, IoT-Sensor values read from USB or Bluetooth... Once you implemented a **YieldDb backend** which *yields* rows one by one, you can perform any kind of SQL-like query on it.

That's the reason why it is called **YieldDb**. Yield anything you like and query it like a database.

## Introduction

Coming soon


## License
MIT
