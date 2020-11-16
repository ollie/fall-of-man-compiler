# Fall of Man Compiler

This is a story-in-progress being told by _Emperor_Cartagia_ (R.K. Katic) on Reddit’s _[ThePhenomenon](https://www.reddit.com/r/ThePhenomenon/)_. It was inspired by [GroveJay’s Phenomenon_Compiler](https://github.com/GroveJay/Phenomenon_Compiler).

Content belong the its owner (R.K. Katic) and the tool itself can be shared and modified freely (MIT). Please if you find an error or it’s simply out of date, please open an issue or pull request.

## Development

```sh
# To compile HTML pages:
$ rake compile

# To view it on your machine:
$ open index.html

# To re-compile HTML pages:
$ rake recompile

# To view it in an iPhone Simulator:
$ rake server
# And then open "http://127.0.0.1:4567/" in Simulator's browser.

# To delete "data/posts/fall-of-man/":
$ rake clean

# To delete "data/fall-of-man/" and generated HTML pages:
$ rake clobber
```

* https://www.reddit.com/dev/api/
* https://github.com/reddit-archive/reddit/wiki/api
* https://github.com/reddit-archive/reddit/wiki/OAuth2
* https://www.reddit.com/prefs/apps
