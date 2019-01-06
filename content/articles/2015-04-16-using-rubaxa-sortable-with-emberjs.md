# Using RubaXa Sortable with Ember.js

<img src="/assets/posts/Sortable.gif" width="314">

[Sortable by RubaXA](http://rubaxa.github.io/Sortable/) is a great library for visually sorting elements in HTML apps.
Sadly it has [no built-in support for Ember.js](https://github.com/RubaXa/Sortable/issues/175), so I thought I would elaborate here how I added it to a client's [Ember.js](http://emberjs.com/) app.

## Creating a SortableList component

app/components/sortable-list.js:

```js
import Ember from 'ember';
import Sortable from 'npm:sortablejs'; // this requires Ember CLI with ember-browserify, which is great!

export default Ember.Component.extend({
  init: function() {
    this._super();

    Ember.assert('required `viewModels` param is set', !Ember.isNone(this.get('viewModels')));
  },
  tagName: 'ul',
  classNames: ['sortableList'],
  actions: {
    removeItem: function(index) {
      this.sendAction('removeItem', index);
    }
  },
  didInsertElement: function() {
    console.debug('Setup Sortable in didInsertElement');

    let s = Sortable.create(document.getElementById(this.get('elementId')), {
      draggable: ".sortableTopicListItem",
      onSort: (evt) => {
        if (evt.type !== 'sort') {
          console.debug('Skipping event that is not sort.')
          return;
        }

        if (evt.oldIndex === evt.newIndex) {
          console.debug('NOOP, evt.oldIndex === evt.newIndex; not sending action; not removing element');
          return;
        }

        console.debug(`evt.oldIndex = ${evt.oldIndex} -> evt.newIndex = ${evt.newIndex}`);

        let dragItem = evt.item;
        dragItem.parentNode.removeChild(dragItem);

        this.sendAction('itemMoved', evt.oldIndex, evt.newIndex);
      },
    });

    this.set('Sortable', s); // for later destruction
  },
  willDestroyElement: function() {
    console.debug('destroying Sortable in willDestroyElement');
    this.get('Sortable').destroy();
  }
});
```

app/templates/components/sortable-list.hbs:

```handlebars
{% raw %}
{{#each viewModels as |viewModel index| }}
  <li class="sortableTopicListItem">
    {{viewModel.displayName}}
    <i {{action removeItem index}} class="remove">✖</i>
  </li>
{{/each}}
{% endraw %}
```

## Using the SortableList component

Showing items with a SortableList is now very easy. All you have to do is supply some `viewModels` which have `displayName` property.

```handlebars
{% raw %}
{{sortable-list viewModels=viewModels itemMoved='moveItem' removeItem='removeItem'}}
{% endraw %}
```

It get's a little more complicated, when you want to reflect the actions that took place in the DOM in your internal data model.

For this the work the enclosing component has to implement `moveItem` and `removeItem` actions where it recreates the changes in it's internal store.

This is the relevant part from one of my enclosing components:

```js
actions: {
  moveItem: function(oldIndex, newIndex) {
    Ember.assert('required `oldIndex` param is set', !Ember.isNone(oldIndex));
    Ember.assert('required `newIndex` param is set', !Ember.isNone(newIndex));

    console.debug(`oldIndex = ${oldIndex} -> newIndex = ${newIndex}`);

    let references = this.get('value'); // Your underlying array

    let movingReference = references.objectAt(oldIndex);

    references.removeAt(oldIndex, 1);
    references.insertAt(newIndex, movingReference);
  },
  removeItem: function(index) {
    Ember.assert('required `index` param is set', !Ember.isNone(index));

    let references = this.get('value');
    references.removeAt(index, 1);
  }
}
```

I hope this is helpful for everyone looking to solve a similar problem.
