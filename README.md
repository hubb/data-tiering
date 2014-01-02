## Data Tiering [![Build status](https://travis-ci.org/hubb/data-tiering.png)](https://travis-ci.org/hubb/data-tiering)


**Data tiering** is a mechanism we currently use at [HouseTrip](http://www.housetrip.com) to reduce database contention for our search.
It’s inspired by the double buffering used in video cards.

The idea is to have search queries not hit the main database tables and compete with updates and other queries, but instead have copies of relevant tables. Those tables will be refreshed every few minutes. We use it for all tables that get heavy writes and reads.
Every one of these regular tables now also has two clones: The front table and the back table.

Most parts of the application will keep using the original table for reads and writes.
Any read-intensive part of the application (e.g. searching) will use the front table.
No part of the application will ever use the back table.
Every few minutes, a task (errand in our jargon) will sync all recent changes from the regular to the inactive table. Then the front and the back table will be swapped.

Conceptually:

```

           ┌─────────────┐
   read <- │ table_front │
           └─────────────┘
           ┌─────────────┐            ┌───────┐
           │ table_back  │ <- update  │ table │ <-> read/︎write
           └─────────────┘            └───────┘

```


Read more on our [blog post](http://dev.housetrip.com/2013/11/15/data-tiering/)

### Install

Add the gem `data_tiering` to your Gemfile and run `bundle install`.

### Using

You need to setup at least 3 things:
- the cache DataTiering is gonna use to store the current active number
- the models you want to data-tier
- include `DataTiering::Model` inside the ActiveRecord class you want to data-tier

```
DataTiering.configure do |config|
  config.cache = Rails.cache
  config.models_to_sync = [MyActiveRecordModel]
end
```

### Testing

By default, DataTiering uses MySQL for test.
You'll need a database:

```
$ mysql -u root
> create database data_tiering_test;
Query OK, 1 row affected (0.00 sec)
> use data_tiering_test;
Database changed
> create table data_tiering_sync_logs(table_name varchar(255), started_at datetime, finished_at datetime);
Query OK, 0 rows affected (0.01 sec)
> exit
```


### NOTES

Assumes you're using active record and is correctly configured with an ActiveRecord::Logger

