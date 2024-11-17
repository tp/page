# Storing binary data in Flutter

Data storage in a Flutter app initially usually focuses on storing some domain objects (e.g. chat messages), whereas binary data (files) are often either loaded on demand (e.g. attachment downloads) or cached transiently with something like [`cached_network_image`](https://pub.dev/packages/cached_network_image) (e.g. for profile images). 

But what is to be done when one needs to permanently store files with the app, either as a local cache to reduce network usage across app runs, or to support offline functionality?

Let's look it this from the perspective of persisting profile images, as these would generally be small enough to allow this thought experiment and to not force us into any specific storage medium by default.

## Local files with pointers from the entities

Imagine a user class like `typedef User = ({int userId, String name, String? profileImagePath })`. The `profileImagePath` can be used to refer to a file on disk. This is easy enough to start with and populate initially, it would just be important to remove this file every time the that specific `User` object is either removed or updated to point to a new profile image path.  
Because when looking into the "file folders" afterwards (in some clean up operation), it's probably not easy to identify which files are actively in use, and which are not and thus could be removed.

## Storing files separately in the database

If we just need to store some files by known keys (e.g. `profile_image_123`), we could set up an [`IndexedEntityStore`](https://pub.dev/documentation/indexed_entity_store/2.0.0-dev2/indexed_entity_store/IndexedEntityStore-class.html) like this that stores the image like this:

```dart
typedef ProfileImage = ({int userId, Uint8List data});

/// Stores the profile images by user ID, 
final profileImageConnector = IndexedEntityConnector<ProfileImage, int, Uint8List>(
  entityKey: 'profile_images',
  getPrimaryKey: (t) => t.userId,
  getIndices: (index) {},
  serialize: (t) => t.data,
  deserialize: (s) => (userId: -1, data: s),
);
```

The problem with this approach is approach is similar to the file storage above. While we can easy check whether we have a specific profile image stored for a user and then retrieve it, we can not (with the current library methods) get a list of all the profile images with their user IDs as the key is only used for storage but then not returned in `deserialize` or available to be queried (e.g. there is no `getAllKeys`).  
This minor limitations could of course alleviated in the store's API (though it's questionable whether this would be a broadly useful extension of it), but when we work with what is available right now, we would still have to manually clean up each profile image when the user is deleted.

In a purpose-built SQLite-based storage for this use-case, one could of course have a foreign key from the profile images to the user, to ensure that they are removed in unison – or just make the profile image a column in the user table.

## Storing the file with the entities

Another approach would be to store the file alongside the entity in whatever object storage the app uses. This introduces some obvious limitations, like the maximum file size (which is probably fine for a profile picture, not so much for a home video), and the amount of files any entity could refer to (is it 1 or 2, or `n`?).

It would probably not be advisable to put the profile image directly on the `User` object using any approach (like `typedef User = ({int userId, String name, Uint8List? profileImage })`), as that would leave no way to pass around the `User` without the image data.
Also when serializing this, one would have to handle the primitive data and the user image separately, as the usual `toJSON` would not be satisfactory by default.

## Storing files with metadata

So, if one still wants to store the files in the database, but not directly with the containing entity (such that also one-to-many relationship would also be possible without building bigger and bigger BLOBs), one might choose to save the file plus some metadata as its own entity.

The constraint of our chosen storage solution is though, that we only get one database field to write everything into. Thus we have to implement a storage format that can handle both the metadata and the binary data. In this case we'll assume that the metadata is much smaller than the actual data, and will prepend the metadata (as JSON in this case) in front of the `Uint8List` binary data.

The storage inside the database would look like this:

```
-------------------------------------------------------------
| Metadata length | Metadata JSON |       Binary data       |
-------------------------------------------------------------
     4 bytes        $length bytes           * bytes
```

The implementation of that storage approach might looks like this:

```dart
typedef ImageWithMetadata = ({ImageMetadata metadata, Uint8List data});

final imageWithMetadataConnector =
    IndexedEntityConnector<ImageWithMetadata, int, Uint8List>(
  entityKey: 'user_profile_image',
  getPrimaryKey: (t) => t.metadata.userId,
  getIndices: (index) {
    index((t) => t.metadata.userId, as: 'userId');
    index((t) => t.metadata.fetchedAt, as: 'fetchedAt');
  },
  serialize: (t) {
    final metadataJSON = JsonUtf8Encoder().convert(t.metadata.toJSON());

    final lengthHeader = Uint8List.view(
      // uint32 is enough for 4GB of metadata
      (ByteData(4)..setUint32(0, metadataJSON.length)).buffer,
    );

    return (BytesBuilder(copy: false)
          ..add(lengthHeader)
          ..add(metadataJSON)
          ..add(t.data))
        .takeBytes();
  },
  deserialize: (s) {
    // Get the lenght of the metadata
    final metaDataLength = ByteData.view(s.buffer).getUint32(0);

    final jsonDecoder = const Utf8Decoder().fuse(const JsonDecoder());
    final metaData = ImageMetadata.fromJSON(
        // pass a view into the metadata into the JSON decoder
      jsonDecoder.convert(Uint8List.view(s.buffer, 4, metaDataLength))
    );

    return (
      metadata: metaData,
      // Pass out the binary data as a read-only view into the raw value retrieved from the database
      data: Uint8List.view(s.buffer, 4 + metaDataLength).asUnmodifiableView(),
    );
  },
);

class ImageMetadata {
    final int userId;
    final DateTime fetchedAt;
    final Uri fetchedFrom;

    // […] implementation of toJSON/fromJSON etc. is omitted for brevity
}
```

With this approach we can just retrieve the profile image with it's metadata whenever we need it. As we stored the `userId` and `fetchedAt` properties as indexed columns, we can also easily query it for 
* no longer known user IDs (in case there was a bug and not all profile images where cleaned up when the user was deleted)
* remove stale images (say `fetchedAt` is older than 7 days)
* Check the metadata's original request URL upon read and re-fetch the image if the server has a new version available

A full-fledged example of this approach is available in [the repository here](
https://github.com/LunaONE/indexed_entity_store/blob/f35b55749f3afa1eb4b827ccb26b0e49888581aa/example/lib/src/examples/binary_data_storage.dart).

## Next steps

For the last example it would be super beneficial if we could add a foreign key constraint between the profile image entity and the known users, thus ensuring that the images get cleaned up when a user gets deleted.  
This is a further direction to explore in the library, as it seems universally useful, and guarding against this from every possible angle seems cumbersome in the application code (as only the database can reliably enforce such an invariant).

Another abstraction to build on top of foreign key approach could be to combine disk file storage with such an external metadata storage, where insertions and deletions automatically handle the underlying file operations.  
This seems much easier to get right on a single file basis for just `read`/`write` instead of handling it for various entity types whenever they get updated in the database.
