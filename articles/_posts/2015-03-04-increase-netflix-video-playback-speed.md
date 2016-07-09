---
title: Increase Video Playback Speed on Netflix
layout: default
---

Like some other [people on the internet](http://www.reddit.com/r/netflix/comments/2ikk00/questionmeta_can_i_speed_up_the_playback_of_movies/) I was frustrated that I couldn't speed up the playback speed of Netflix videos like I got used to on YouTube.

With this little peace of code one can easily increase the playback speed of the main video:

```
document.getElementsByTagName('video')[0].playbackRate = 1.2
```

Turns out it is not as generally useful as increasing [podcast playback speeds](/2015/02/22/increased-podcast-playback-speeds.html), though.  
While speedier dialogues are great, the unnatural fast body movements at higher speeds distract me a lot.
