---
title: File / Image Input Component for Ember.js
layout: default
---

# {{ page.title }}

In order to enable a great user experience I wanted to show the user's newly selected profile picture in one of our clients web apps right after she choose the desired file in her browser's file picker dialog.

Unfortunately this is not yet as easy as a simple {% raw %}`<input type="file" file={{file}}>`{% endraw %}.

Having found [this pure JavaScript implementation](http://www.html5rocks.com/en/tutorials/file/dndfiles/) of similar behaviour on HTML5 Rocks, I set out to port it to Ember.

Since I was not able to find any recent Ember-compatible code solving this problem, I created my own version using the latest Ember conventions: a [component](http://emberjs.com/api/classes/Ember.Component.html).

app/components/file-input.js:
{% highlight javascript linenos %}
import Ember from 'ember';

export default Ember.TextField.extend({
  type: 'file',
  change: function(e) {
    let self = this;

    var inputFiles = e.target.files;
    if (inputFiles.length < 1) {
      return;
    }

    let inputFile = inputFiles[0];

    let fileInfo = {
      name: inputFile.name,
      type: inputFile.type || 'n/a',
      size: inputFile.size,
      date: inputFile.lastModifiedDate ?
            inputFile.lastModifiedDate.toLocaleDateString() : 'n/a',
    };

    var fileReader = new FileReader();

    fileReader.onload = function(e) {
      let fileReader = e.target;
      fileInfo.dataURL = fileReader.result;

      self.sendAction('fileChanged', fileInfo);
    };

    let firstFile = e.target.files[0];
    fileReader.readAsDataURL(firstFile);
  },
});
{% endhighlight %}

app/components/image-input.js:
{% highlight js linenos %}
import Ember from 'ember';

export default Ember.Component.extend({
  file: null,
  actions: {
    fileSelectionChanged: function(file) {
      this.set('file', file)
    },
  },
});
{% endhighlight %}

app/templates/components/image-input.js:
{% highlight html linenos %}
{% raw %}
<strong>Image Input</strong><br>

{{#if file}}
<img src="{{file.dataURL}}" width="300">

<ul>
  <li>Name: {{file.name}}</li>
  <li>Type: {{file.type}}</li>
  <li>Size: {{file.size}} bytes</li>
  <li>Last modified: {{file.date}}</li>
</ul>
{{/if}}

<br>

{{ file-input fileChanged="fileSelectionChanged"}}
{% endraw %}
{% endhighlight %}

Now usage is as easy as {% raw %}`{{image-input}}`{% endraw %}!

The result looks like this:

<!-- ![image-input Ember component](/assets/posts/ember.js_image-input_component.png) -->
<img src="/assets/posts/ember.js_image-input_component.png" width="314">
