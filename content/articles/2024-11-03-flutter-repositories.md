# Designing repositories for Flutter apps on top of `IndexedEntityStore`

[`IndexedEntityStore`](https://pub.dev/packages/indexed_entity_store) is a new _synchronous_ database package to handle your Flutter app's persistent storage in an easy way, with a focus on simplicity and development speed.

Though it handles data management and efficient querying, it's only a small building block in the app architecture. For most use-cases one wants to probably build repositories on top of this storage – in combination with one's backend APIs – to put a full data-layer in place.

Let's now consider 3 examples approaches for how to do this. The API and usage of the package itself is not documented in detail, instead refer to the [documentation](https://pub.dev/packages/indexed_entity_store/example) if needed.

## All the data, all the time

Consider a simple todo list app, where all the data is available all the time. If the app has a syncing capability, that might still run initially and throughout the usage of the app, but once these jobs complete 100% of the data of the app is available locally. This approach can lead to a very simple design.

```dart
class TodoRepository {
    TodoApi remoteApi;

    IndexedEntityStore<Todo, int> store;

    // Depending on the application's needs, this would either run initially before the user can interact with the app, or in the background
    Future<void> fetchAll() async {
        // This could be extended to only get new todos on subsequent calls, and then insert those locally
        final todos = await remoteApi.getTodos();

        store.insertMany(todos);
    }

    /// Return a live-updating query to the list of open todo items
    QueryResult<List<Todo>> getOpenTodos() {
        /// while the column access uses `String`s, it's still checked at runtime to refer to an indexed column
        return store.query((cols) => cols['done'].equals(false));
    }

    // Returns a "view" onto a stored todo item
    // The caller will automatically receive updates through the `ValueListenable` interface whenever the stored todo was changed in the database
    // The returned todo item is optional (nullable), as we assume that it might not have been synced to the local database when the request is made (e.g. because a todo detail page was opened via a deep link).
    // If the user could only navigate to existing/known items in the app, we could make it non-optional, which would simplify the usage site a bit.
    QueryResult<Todo?> getTodo(int id) {
        return store.get(id);
    }

    Future<void> updateTodo(Todo todo) {
        store.insert(todo);

        // Failure handling for this is left as an exercise to the reader. Depending on whether the app is offline-first or requires connectivity and instant updates on the server,
        // we could either store the todo with some "sync pending" flag locally and try again later, or roll back the local update in case the server call failed.
        await remoteApi.updateTodo(todo);
    }
}
```

Both read methods above (`getOpenTodos` and `getTodo`) return a `QueryResult<T>` which implements `ValueListenable<T>`. In a Flutter `Widget` one could use a subscription to these results in combination with a `ValueListenableBuilder` like this:

```dart
class _TodoListState extends State<TodoList> {
  late final openTodos = widget.repository.getOpenTodos();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: openTodos,
        builder: (context, openTodos, _) {
            return Column( // or ListView.builder etc.
                mainAxisSize: MainAxisSize.min,
                children: [
                for (final openTodo in openTodos)
                    CupertinoListTile(
                        title: Text(openTodo.text),
                    ),
                ],
            );
        },
    );
  }


  @override
  void dispose() {
    // important to unsubscribe here, so the database does not send any more updates into the `QueryResult`
    openTodos.dispose();

    super.dispose();
  }
}
```

## On-demand data loading with offline storage

Next let's image a use-case where the data is not (or can not) all be known beforehand, and we need to fetch it on demand. This could be the case for example with an event-planning app, where event details are fetched on first view and which would from then on be available locally (with potential background updates from the server to communicate new changes).

```dart
class EventRepository {
    EventApi remoteApi;

    IndexedEntityStore<Event, int> store;

    // The list of events in a category is handled ephemerally in this case and not persisted in the database
    // For simplicity's sake we're using a `Future` here (and thus likely a `FutureBuilder` in the `Widget`)
    Future<List<EventsSummary>> getEventsInCategory(int categoryId) {
        return remoteApi.getEvents(categoryId);
    }

    // Returns a "view" onto an event detail (containing more information than just the summaries above)
    QueryResult<EventDetail?> getEventDetails(int id) {
        final event = store.get(id);

        if (event.value == null) {
            // event is not yet loaded into the store, so we need to fetch it
            remoteApi.getEvent(id).then((event) => store.insert(event));
        }

        return event;
    }
}
```

The simple method signature of `getEventDetails` hides one important fact though: While we can distinguish between "loading" and "loaded" (`null` vs. an non-`null`), the caller will not get notified if the remote loading fails.  
To expose this further information we could change the signature to `DisposableValueListenable<AsyncValue<EventDetail>>`, but merging the local state with the latest API result is a little bit more involved and thus not part of this introduction. But a [full example showing that approach is available here](https://github.com/LunaONE/indexed_entity_store/blob/058564857d87478e7eac3f5ebf0a05fd6a15f607/example/lib/src/examples/async_value_group_and_detail.dart#L169). Once this is abstracted and a common pattern in the repository implementations, this could likely become just second nature though.

## On-demand data (alternative)

For the practically asynchronous data on-demand case as in `getEventDetails` above, a nicer signature might be `FutureOr<DisposableValueListenable<EventDetail>>`, as that clearly distinguished between "has the data been loaded successfully" and "here is a view to the latest local data" (non-`null` even, as we then expect it to stay available).


This could be implemented like this:

```dart
import 'package:value_listenable_extensions/value_listenable_extensions.dart';

class EventRepository {
    …

    Future<DisposableValueListenable<EventDetail>> getEventDetails(int id) async {
        final event = store.get(id);

        if (event.value == null) {
            try {
                final remoteEvent = await remoteApi.getEvent(id);

                store.insert(remoteEvent);
            } catch (e) {
                event.dispose(); // failed to load the data, close view to database

                rethrow;
            }
        }

        // If we reached this, we now know that we have a value in the local database, and we don't expect it to ever be deleted in this case, and thus can "force unwrap" it.
        return event.transform((e) => e!);
    }
}
```

To me this signature looks better, but we have to be careful when using it. It's important to always `dispose` the query result view (which is now wrapped inside a `Future`), so we'll have to keep that in mind. Especially since the `Widget` using it could already be dismissed before the `Future` resolved (e.g. when the data loading was so slow that the user went back), in which case we still have to clean up the query result should it become available.

```dart
class _EventDetailState extends State<EventDetail> {
  late final event = widget.repository.getEventDetails(widget.eventId);

  @override
  Widget build(BuildContext context) {
     return FutureBuilder(
        future: event,
        builder: (context, data) {
            if (!data.hasData) {
                return const CupertinoActivityIndicator();
            }

            return ValueListenableBuilder(
                valueListenable: event.requireData,
                builder: (context, event, _) {
                return EventTitle(event: event);
                },
            );
        },
    );
  }


  @override
  void dispose() {
    // Imporant to cancel the underlying value listenable here when it has finished loading, even if that may happen after the widget is already disposed.
    event.then((eventResult) => eventResult.dispose());

    super.dispose();
  }
}
```

If Dart had something like [Swift's structured concurrency](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/concurrency/#Task-Cancellation) we might be able to cancel the work "inside" the `Future` in a more straightforward way, but while that is not the case an approach like the one shown above must be taken.

Both usages inside `build` and `dispose` can be greatly simplified though by the use of some helpers. We can easily imagine a `FutureValueListenableBuilder` that handles both the unwrapping of the future and listening to the changes inside it, as well as an extension method on `Future<DisposableValueListenable<T>>` which would make the clean up shorter.
