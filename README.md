# homebrew-bsdmainutils
Homebrew formula for the Debian version of bsdmainutils based on
modern FreeBSD utilities.

My primary motivation in getting this was to install the Debian
version of `cal` which supports the `-3` flag.

## Installation ##
You can install this tap and package with the following commands:
```sh
brew tap b4hand/bsdmainutils
brew install bsdmainutils
```

## Known Bugs ##
* The `write` command doesn't work properly. It appears to require
  priviledged access and even with the proper priviledges can't seem
  to find `wtmp`. I personally don't care if this tool is broken as I
  have no use for it on a single user Mac laptop. ;)
* It's possible some of the other utilities are broken as well. I
  haven't really tried most of them out.
