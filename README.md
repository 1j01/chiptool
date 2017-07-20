# chiptool

an experimental music making app.

**pre-alpha**, but [online](http://1j01.github.io/chiptool/)
if you want to see what it is so far (not much!)

it's called chiptool currently because it'll probably have a focus on chiptune,
but that might change, at which point I'd try to think of a better name.


## hey look over there it's a better app

If you want a good chiptune making app, check out [BeepBox](http://beepbox.co).

(It's actually like, a thing that you can use!)

### accidental review of it:

The note editing interface is pretty sweet,
and I like how it applies to percussion as well.
It's a little quirky how the note lengths get partitioned so you can do chords,
and making curves can be tricky in some cases,
but the interface, and interface decisions, are understandable.

There's a good amount of options for the synths,
and all the options I'd want for saving/loading and exporting.

The patterns system is about what you'd expect.
Pretty run-of-the-mill, but useable.
Limited options for copy/paste.

There are generally limited options for manipulating multiple notes.
That's probably my biggest gripe with it.
* I made a rendition of Pachelbel's Canon,
but it's rather fast as I was afraid of running out of pattern numbers since it seems to only go up to 8,
and there's no options to half or double durations of sections.
And also the tempo slider doesn't go very low.
(Side note: doubling durations manually is harder than halving.)
(Doubling or halving the duration of a section of patterns would be complicated by having to create new patterns.)
* If you want to add a section to the middle or start,
or otherwise restructure a song,
you have to shift things over manually.
* Later I was trying to make a chiptune cover of Space Girl by The Imagined Village,
but I wasn't sure whether to include a half measure lead-in,
and didn't want to have to manually shift everything over in each pattern.

(Although I could do these operations with code, exporting, manipulating and importing JSON.)


## todo(s)

boring todo:

* undo/redo
* right click to delete
* adjust default glide to be more like 0.2s rather than the length of a note
* import/export JSON
* versioned and automatically upgraded format
* playback control other than play/stop
* multiple concurrent synths
* synth parameters
* support for touch-only interaction for mobile devices

vague todo:

* explore ideas around **looping** and reuse of patterns **with variation**
(I want something that's like copy and paste, but better)
* the editing interface isn't good for improvisation;
you naturally want to **play it like an instrument**,
but it doesn't directly record what you play
* it's also not super expressive for when editing;
you should be able to make glides of different lengths and **different kinds of curves**
* **automation** (of anything and/or everything);
maybe the notes editing surface and the automation curves editing surface can be unified;
what about e.g. swapping out an instrument entirely?
what would the interface have to look like if you could automate literally anything?
a code editor, probably, at that point.
okay, but what if you could automate everything within reason?
idk, define reason.
you define reason.
thanks, I like to think so.
* **midi** stuff (export, maybe import; recording, probably)


## License

[MIT](./LICENSE)


## P.S.

If you have ideas about,
how music production software feels grounded in the past,
how concepts could be unified or simplified,
or how some of the above 'vague todo' items should work,
[open an issue][] or [send me an email][email me]
(whichever feels appropriate)

Other crazy ideas:
* Use neural networks to transcribe audio of singing, humming, whistling, and/or playing instruments.
If you want to collaborate on this, [email me][]!
I haven't used neural networks before, so it would definitely be a "learning" experience for me.
* Mechanical representation of a song with circular loops, maybe even with gears, linkage, and/or grooves
(This is probably a silly idea; although... it could be awesome if you could actually assemble custom machinery to make a physical version of a song)

[open an issue]: https://github.com/1j01/chiptool/issues
[email me]: mailto:isaiahodhner@gmail.com
