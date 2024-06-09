# NOTE

This repo is no longer one of the "known" buckets for scoop. :-)
Please run this:

```
PS> scoop bucket rm nirsoft
PS> scoop update
PS> scoop bucket add nirsoft
```

To make sure you're on the latest, you can run this and verify the output:

```
PS> scoop bucket list
Name       Source                                             Updated              Manifests
----       ------                                             -------              ---------
main       https://github.com/ScoopInstaller/Main             6/9/2024 6:30:58 AM       1327
nirsoft    https://github.com/ScoopInstaller/Nirsoft          6/7/2024 10:24:26 PM       283
```

# scoop-nirsoft

A [Scoop](http://scoop.sh) bucket of useful [NirSoft](https://www.nirsoft.net/) utilities.

To make it easy to install apps from this bucket, run:

    > scoop bucket add nirsoft

## Why does this exist?

For an app to be acceptable for the main bucket, it should be:

* open source
* a command-line program
* the latest stable version of the program
* reasonably well-known and widely used

The "extras" bucket has more relaxed requirements, so it's a good place to put anything that doesn't quite fit in the main bucket.

The "nirsoft" bucket is specifically for the many (hundreds) of utilities found on the NirSoft website.
