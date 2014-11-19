FlickrExifTagger
================

This is a simple and hacky script to add machine tags to Flickr images
describing the lens used for a photo. Machine tags are one way to add meta
information to Flickr images in a somewhat more sorted way that the usual tags
using namespaces and a key-value system. The Flickr FAQ give a [short
introduction on machine tags](http://www.flickr.com/help/tags/#613430). Using
machine tags to describe the lens used for a photo normally duplicates the
information already existing in the exif tags of the photo (if the camera adds
these information) but allows searching for lenses as searching for exif
information is not yet very well usable using the Flickr API. Moreover, most
cameras add the lens type in a maker or even camera specific form to the exif
tags, which complicates a unified search over all camera brands.

FlickrExifTagger is a really simple script written in Ruby that uses
[flickraw](http://hanklords.github.com/flickraw/) to access the Flickr API. It
iterates over all photos of the user's account, starting with the most recent
photo, reads the exif information and uses a hard-coded set of rules to add
lens machine tags.

This script is really not intended to be used without modifications in the
code!

## Usage

Preconditions:

```
gem install flickraw
```

Basic usage:

```
git clone https://github.com/languitar/FlickrExifTagger.git
cd FlickrExifTagger
ruby flickrExifTagger.rb
```

Follow the instructions on screen for authentication against the Flickr API.

## License

see [COPYING](https://github.com/languitar/FlickrExifTagger/blob/master/COPYING) file
