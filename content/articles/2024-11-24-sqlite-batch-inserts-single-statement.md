# Speeding up batch inserts in SQLite using dynamic statements

[`indexed_entity_store`](https://pub.dev/packages/indexed_entity_store)'s `writeMany` used to insert a batch of items in a single transaction, but using _n_ individual `REPLACE INTO` statements (and then the corresponding index updates). In my testing I saw it take ~10ms for 1000 items with a small JSON payload (which serialization time is included in the total).
This [is considered best practice](https://github.com/simolus3/sqlite3.dart/issues/260#issuecomment-2447854905) and does seem okay for most practical one-time batch imports of data (such that one did not have to resort to an `async` initial setup to avoid multi-frame drops).

Initially I wondered why, even inside the transaction, we had to loop over the individual inserts and could not execute a single statement which would write all data at once (up to a point I suppose, as there is surely a practical limit on how large a query can get, though than a similar constraint might apply to the in-progress transaction side.)

As it turns out we can insert multiple row just fine in a single statement, it's just a little bit unusual to write as SQLite does not allow binding to lists of values.  
So from our single insert compiled statement (`REPLACE INTO entity (type, key, value) VALUES (?, ?, ?)`) we have to switch to a dynamically generated on that accounts for the number of inserts we want to do: `REPLACE INTO entity (type, key, value) VALUES (?1, ?, ?), (?1, ?, ?), … (?1, ?, ?)`. That way we can call execute this statement with a concatenated parameter list of all the entities we want to write.[^1]

This pattern has been implemented in [this PR](https://github.com/LunaONE/indexed_entity_store/pull/26), and indeed shows some nice improvements for my tests of batch sizes 1,000 and 10,000:


|Batch size|Transaction (old)|Single statement (new)|
|-|-|-|
|1,000|`writeMany` took 7.41ms<br>`writeMany` again took 17.59ms|`writeMany` took 2.47ms<br>`writeMany` again took 5.38ms|
|10,000|`writeMany` took 69.68ms<br>`writeMany` again took 134.04ms|`writeMany` took 21.74ms<br>`writeMany` again took 43.21ms|

Overall this resulted in a nice 3x speed-up. That is a fine start, but does not really change the ballpark speed of the operation in the general case.

Further I wondered whether the small payload sizes used in the example would benefit either one of the approach. So I ran another test where each entity had a ~10kB payload JSON.


|Batch size|Transaction (old)|Single statement (new)|
|-|-|-|
|1,000|`writeMany` took 261.57ms<br>`writeMany` again took 474.71ms|`writeMany` took 133.56ms<br>`writeMany` again took 193.89ms|
|10,000|`writeMany` took 2334.00ms<br>`writeMany` again took 5128.63ms|`writeMany` took 1159.16ms<br>`writeMany` again took 1849.37ms|

In this case the new approach still resulted in a 2x speed-up and did not run into any size limits. I did not measure the peak memory usage, but very likely this would have been higher in the new case, were all serialized entities are passed to the SQLite library in 1 call vs. the loop-approach, where Dart's GC has a chance to clean up each individual entity after passing it off.

Lastly I wondered how much of a penalty in these real-life tests was the overall JSON serialization (which one can exchange for a smaller and/or more efficient storage format). So in the last comparison I just saved the primary payload string straight to the database, without any JSON serialization:

|Batch size|Transaction (old)|Single statement (new)|
|-|-|-|
|1,000 (small)|`writeMany` took 6.27ms<br>`writeMany` again took 12.00ms|`writeMany` took 1.87ms<br>`writeMany` again took 3.29ms|
|1,000 (large)|`writeMany` took 248.43ms<br>`writeMany` again took 451.07ms|`writeMany` took 86.97ms<br>`writeMany` again took 138.00ms|
|10,000 (small)|`writeMany` took 59.21ms<br>`writeMany` again took 121.93ms|`writeMany` took 12.74ms<br>`writeMany` again took 32.15ms|
|10,000 (large)|`writeMany` took 1925.63ms<br>`writeMany` again took 4741.23ms|`writeMany` took 743.32ms<br>`writeMany` again took 1432.79ms|

Interestingly this did not result in a big speed-up compared to building the JSON values in the previous test run. But somehow the new approach benefited much more from this than the old one, making it even faster especially for larger payloads.

Overall I would have expected to be able to gain more by doing less transitions from Dart to the SQLite C-library, but this confirms just how fast the in-process `ffi` approach is and bigger gains would have to come from elsewhere.  
The biggest difference in the approach seems to driven by the library's use of indices (to efficiently find entities later). When I disable them for testing, both approaches come very close to each other, but do not get significantly faster than the "single insert with search indices" approach. That suggests that there is a rather penalty being paid for updating the index table individually for each row entry (inside the transaction).

[^1]: The `?1` in all these cases is the `entity` type, which is the same across all rows, and thus we provide it only once to keep the parameter list length a bit down.
