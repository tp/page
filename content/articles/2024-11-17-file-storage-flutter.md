# File storage in Flutter apps (Part 2)

[Last week's article](articles/binary-data-sqlite-flutter) looked at various implementations of how to store files with metadata in SQLite using the package [indexed_entity_store](https://pub.dev/packages/indexed_entity_store). This time, let's look at cases where you want to have the actual files on disk, with only its metadata stored in a database. Reasons for this might be that the files are very large, accessed often (e.g. for sharing, uploading), or need to be edited in place.

To get consistency across the files and their metadata, let's implement a store that exposes a subset of the usual operations, but which takes care of the file management in addition to the metadata storage.

The final interface should look something like this:

```dart
class FileStore<T> {
  // The directory this store is managing, and where it places its copy of the files
  final Directory baseDirectory;

  // Creates or updates an entry for T, backing it with the contents of `file`
  // If `file` is not "owned" by this store (e.g. not in its managed directory),
  // it will copy the file to take ownership of a copy of it.
  void write(T metadata, File file);

  // Returns a list of metadata + files matching the given query
  // The caller gets access to the files as they are managed by this store (e.g. residing in `baseDirectory`)
  // The caller may modify the files in place, but must not delete them on disk directly. For that they must use `delete` on this store in order to clean up the metadata as well.
  List<(T, File)> query(…);

  // Deletes the entry `metadata` refers to, as well as the backing file 
  void delete(T metadata);
}
```

This implementation already incorporates some design choices, which could be adapted for different use-cases. Here the store will make sure that it always "owns" the underlying file. Thus when a file is added which does not reside in the directory managed by this store, it will copy it there and store a reference to that new location. On the flip-side (the reading) part, it will hand out `File`s referencing its internal storage paths, such that the caller might modify the file in place. This introduces a trade-off though, such that the store itself does not get notified of in-place file modifications (which may or may not be relevant to know about). This could be alleviated by e.g. always copying the files to a temporary location for reading, and expecting the outside to call `write` again after each change (at which point a copy would be written to the store's internal directory)[^1].

An approach like the one outlined above is implemented [as an example here](https://github.com/LunaONE/indexed_entity_store/tree/945725eb02deccd792a34c995f165e25340faf91/example/lib/src/examples/disk_file_store).


For brevity only the `delete` method is shown below, but `write` is similarly the reverse as described above (copying the file into the store's realm if needed), and `get` and `query` are just straightforwards read from the store to get the metadata and file path.

```dart
class DiskFileStore<Metadata, Key> {
  final IndexedEntityStore<FileWithMetadata<T>, K> _store;

  /// Remove the entry identified by [key] from the store, and deletes the backing file
  void delete({
    required K key,
  }) {
    final existingEntry = _store.readOnce(key);
    if (existingEntry != null) {
      File(existingEntry.filepath).deleteSync();

      _store.delete(key: key);
    }
  }
}
```

That's it. By combining the metadata writes with the files, we can now ensure that the pair of them is always up to date, and we have a single, simple interface to manage them together.

The [upcoming 2.0.0 version](https://pub.dev/packages/indexed_entity_store/versions/2.0.0-dev3) of the package will furthermore introduce some additional enhancement for this use-case: As a file usually belongs to some other entity and doesn't exist by itself, it will allow you to reference that "parent entity" from the file's metadata via an index, for example a mail attachment might reference the parent like this: [`index((e) => e.metadata.mailId, as: 'mailId', referencing: 'mails');`](https://github.com/LunaONE/indexed_entity_store/blob/main/test/foreign_key_test.dart#L175-L177). This ensures that all file entries point to a valid parent. And if the parent gets deleted, its files must be cleaned up beforehand.

The above excerpt and the example in general make a lot of assumptions and design choices which might not be ideal for every use-case. But since the full "file store" is only 100 lines of code, I think it's clear that it can be easily adapted to suite one's needs (e.g. handing out temporary files, or using `async` file operations, ensuring notifications for file changes, etc.).

[^1]: On modern copy-on-write filesystems, though would not even need to incur performance penalty for the cases where the file is not modified after all.