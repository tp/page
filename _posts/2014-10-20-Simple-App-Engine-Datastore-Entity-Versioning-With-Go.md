---
title: Simple App Engine Datastore Entity Versioning With Go
layout: default
---

# {{ page.title }}

In a recent project we needed the ability to save every version of a `User`'s profile (type `UserProfile`) in our database, so that we are able track changes over time and restore or review previous versions.

Since there does not seem to be a standard way to do entity versioning with App Engine Datastore entities, I wrote up a quick sample below of how I solved this.

I think there are two basically two way to achieve this whithout data normalization (i.e. storing the latest version in a special place):

- Store an ever increasing version number with the entities. Pick the one with the highest version number when querying. Optionally this can be used to only allow successive saves (from version 3 to 4 to 5 etc.).
- Store the creation/save date with each entity. Pick the entity with the most recent creation date when querying.

(I won't delve into [delta compression](http://en.wikipedia.org/wiki/Delta_encoding) here, which may be worth considering if your entities are sufficiently large or change a lot.)

I opted for a solution based on the entity creation time instead of a entity versioning solution that requires successive entities versions since those can be created without reading the previous entities' version number from the `datastore`.

This also has the benefit that we’re able to restore the state of the whole database for any point in time since all changing entities are tagged with their creation date.

And because writes to a single entity group (in our case the `User`) are strongly consistend and [guaranteed to be executed before the next read](https://cloud.google.com/appengine/docs/go/datastore/#Go_Datastore_writes_and_data_visibility) of entities in that group, we are always seeing the most recently created `UserProfile` in our queries.


## Implemenation & Tests

{% gist c1e25ae24d405a58f081 %}