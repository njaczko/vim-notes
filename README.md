**No longer maintained.**

# njaczko/vim-notes

This is a slimmed-down fork of Peter Odding's [vim-notes](https://github.com/xolox/vim-notes) plugin.

The original vim-notes plugin is great, but it includes plenty of features that
I don't use and depends on [another plugin](https://github.com/xolox/vim-misc).

This plugin provides syntax highlighting and automatic formatting for bulleted lists.
It also supports keywords like `TODO`, `WIP`, `BLOCKED`, `DONE`, and `XXX` that
highlight bullet points.

The `notes` filetype is set when the `.notes` or `.note` file extention is used.

## Example

This note demonstrates most of the features:

```
This is the note title

*Emphatic Text*
 • here's a bullet
 • XXX don't need to do something
 • TODO need to do something
 • DONE did something
 • WIP doing something
 • level 1
    ◦ level 2
       ▸ level 3
          ▹ level 4
             ▪ level 5
                ▫ level 6
 • Check out this `code snippet`
```

It is presented like this:
![vim-notes screenshot](https://raw.githubusercontent.com/njaczko/njaczko/main/assets/vim-notes.png)
