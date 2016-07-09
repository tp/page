---
title: Simple App Engine Datastore Entity Versioning With Go
layout: default
---

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

main.go
{% highlight go linenos %}
package main

import (
	"fmt"
	"time"

	"appengine"
	"appengine/datastore"
)

const (
	KindUser        = "user"
	KindUserProfile = "userprofile"
)

func main() {}

type CreatedAtStruct struct {
	CreatedAt time.Time
}

func (c *CreatedAtStruct) SetCreatedAt(t time.Time) {
	c.CreatedAt = t
}

type CreationDateSetter interface {
	SetCreatedAt(t time.Time)
}

type User struct{}

type UserProfile struct {
	CreatedAtStruct

	Counter int
}

func putVersioned(c appengine.Context, kind string, parent *datastore.Key, v CreationDateSetter) (*datastore.Key, error) {
	if parent == nil {
		return nil, fmt.Errorf("parent must be set")
	}

	v.SetCreatedAt(time.Now())

	return datastore.Put(c, datastore.NewIncompleteKey(c, kind, parent), v)
}

func getLatest(c appengine.Context, kind string, parent *datastore.Key, v interface{}) error {
	q := datastore.NewQuery(kind).Ancestor(parent).Order("-CreatedAt").Limit(1)

	_, err := q.Run(c).Next(v)

	return err
}
{% endhighlight %}

main_test.go

{% highlight go linenos %}
package main

import (
	"testing"

	"appengine/aetest"
	"appengine/datastore"
)

func TestVersionedStorageAfterEachPut(t *testing.T) {
	c, err := aetest.NewContext(nil)
	if err != nil {
		t.Fatal(err)
	}

	userkey, err := datastore.Put(c, datastore.NewIncompleteKey(c, KindUser, nil), &User{})
	if err != nil {
		t.Fatal(err)
	}

	for i := 0; i < 10; i++ {
		p := &UserProfile{Counter: i}
		_, err := putVersioned(c, KindUserProfile, userkey, p)
		if err != nil {
			t.Fatal(err)
		}

		outputProfile := new(UserProfile)
		err = getLatest(c, KindUserProfile, userkey, outputProfile)
		if err != nil {
			t.Fatal(err)
		}

		if outputProfile.Counter != i {
			t.Fatalf("Expected Counter to be %d but it was %d", i, outputProfile.Counter)
		}
	}
}

func TestVersionedStorageAfterAllPuts(t *testing.T) {
	c, err := aetest.NewContext(nil)
	if err != nil {
		t.Fatal(err)
	}

	userkey, err := datastore.Put(c, datastore.NewIncompleteKey(c, KindUser, nil), &User{})
	if err != nil {
		t.Fatal(err)
	}

	upper := 10
	for i := 1; i <= upper; i++ {
		p := &UserProfile{Counter: i}
		_, err := putVersioned(c, KindUserProfile, userkey, p)
		if err != nil {
			t.Fatal(err)
		}
	}

	outputProfile := new(UserProfile)
	err = getLatest(c, KindUserProfile, userkey, outputProfile)
	if err != nil {
		t.Fatal(err)
	}

	if outputProfile.Counter != upper {
		t.Fatalf("Expected Counter to be %d but it was %d", upper, outputProfile.Counter)
	}
}
{% endhighlight %}

[See Gist on GitHub](https://gist.github.com/tp/c1e25ae24d405a58f081)
