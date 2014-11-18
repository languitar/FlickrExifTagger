=begin
A hacky script to tag photos on flickr with lens machine tags based on
information found in the image exif data.

To be useful for you own set of lenses and camera you need to change the
lines defining the tags to add based on the exif information found in the
images (see comment below).

This program is free software; you can redistribute it
and/or modify it under the terms of the GNU General
Public License as published by the Free Software Foundation;
either version 2, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

@author: Johannes Wienke <languitar at semipol dot de>
=end

API_KEY = "25de6f1217a9f614e8782481d0e6ea99"
SHARED_SECRET = "4401b29a4e0ca1df"

OLD_LOGIN_FILE = File.expand_path("~/.flickrexiftagger_login")

require "flickraw"
require "optparse"
require "yaml"

FlickRaw.api_key = API_KEY
FlickRaw.shared_secret = SHARED_SECRET

$login = nil

def doOldLogin

  if !File.file?(OLD_LOGIN_FILE)
    raise "No previous credentials available"
  end

  f = open(OLD_LOGIN_FILE, 'r')
  loginData = YAML::load(f.read())
  f.close

  flickr.access_token = loginData["token"]
  flickr.access_secret = loginData["secret"]

  $login = flickr.test.login

end

def doLogin

  begin
    doOldLogin
    return
  rescue Exception => e
    puts "Using previous credentials failed: #{e.msg}"
  end

  token = flickr.get_request_token
  auth_url = flickr.get_authorize_url(token['oauth_token'], :perms => 'delete')

  puts "Open this url in your process to complete the authication process : #{auth_url}"
  puts "Copy here the number given when you complete the process."
  verify = gets.strip

  begin
    flickr.get_access_token(token['oauth_token'], token['oauth_token_secret'], verify)
    $login = flickr.test.login
    puts "You are now authenticated as #{$login.username} with token #{flickr.access_token} and secret #{flickr.access_secret}"
    f = open(OLD_LOGIN_FILE, 'w')
    f.write(YAML::dump({"token" => flickr.access_token, "secret" => flickr.access_secret}))
    f.close
  rescue FlickRaw::FailedResponse => e
    puts "Authentication failed : #{e.msg}"
    exit(1)
  end

end

if __FILE__ == $0

  doLogin()

  # iterate through all photo pages
  stop = false
  page = 1
  numPhotos = 0
  until stop
    allUserPhotos = flickr.photos.search :user_id => $login.id, :page => page
    puts("Going through page #{page} of #{allUserPhotos.pages} with #{allUserPhotos.perpage} photos per page")

    allUserPhotos.each do |photo|

      info = flickr.photos.getInfo :photo_id => photo.id, :secret => photo.secret
      puts("processing photo #{info.title}")

      exif = flickr.photos.getExif :photo_id => photo.id, :secret => photo.secret
      tagsToAdd = nil
      exif.exif.each do |tag|
        begin
          if tag.tag == "LensType"

            if tag.raw.include?("14-42mm")
              tagsToAdd = 'lens:maker=Olympus,lens:aperture=3.5-5.6,lens:focallength=14-42,"lens:type=Zuiko Digital ED 14-42mm F3.5-5.6"'
            elsif tag.raw.include?("40-150mm")
              tagsToAdd = 'lens:maker=Olympus,lens:aperture=4.0-5.6,lens:focallength=40-150,"lens:type=Zuiko Digital ED 40-150mm F4.0-5.6"'
            elsif tag.raw.include?("(1 22")
              tagsToAdd = 'lens:maker=Sigma,lens:aperture=2.8,lens:focallength=70-200,"lens:type=70-200mm F2.8 EX DG Makro HSM II"'
            elsif tag.raw.include?("35mm F3.5 Macro")
              tagsToAdd = 'lens:maker=Olympus,lens:aperture=3.5,lens:focallength=35,"lens:type=Zuiko Digital 35mm F3.5 Macro"'
            elsif tag.raw.include?("Sigma 10-20mm")
              tagsToAdd = 'lens:maker=Sigma,lens:aperture=4.0-5.6,lens:focallength=10-20,"lens:type=10-20mm F4-5.6 EX DC HSM"'
            elsif tag.raw.include?("None")
              tagsToAdd = 'lens:maker=Lensbaby,lens:focallength=50,"lens:type=Lensbaby Muse Double Glass Optic"'
            end
            break

          elsif tag.tag == "Lens"

            #puts("\tLens is: #{tag.raw}")

            if tag.raw.include?("60.0 mm f/2.8")
              tagsToAdd = 'lens:maker=Nikon,lens:aperture=2.8,lens:focallength=60,"lens:type=AF-S Micro Nikkor 60mm/2.8G ED"'
            elsif tag.raw.include?("10.0-20.0 mm f/4.0-5.6")
              tagsToAdd = 'lens:maker=Sigma,lens:aperture=4.0-5.6,lens:focallength=10-20,"lens:type=10-20mm F4-5.6 EX DC HSM"'
            elsif tag.raw.include?("90.0 mm f/2.8")
              tagsToAdd = 'lens:maker=Tamron,lens:aperture=2.8,lens:focallength=90,"lens:type=SP AF 90mm F/2.8 Di MACRO 1:1"'
            elsif tag.raw.include?("16.0-85.0 mm f/3.5-5.6")
              tagsToAdd = 'lens:maker=Nikon,lens:aperture=3.5-5.6,lens:focallength=16-85,"lens:type=AF-S DX Nikkor 16-85mm 1:3.5-5.6G ED VR"'
            elsif tag.raw.include?("70.0-300.0 mm f/4.0-5.6")
              tagsToAdd = 'lens:maker=Tamron,lens:aperture=4.0-5.6,lens:focallength=70-300,"lens:type=SP AF 70-300 F/4-5.6 Di VC USD"'
            elsif tag.raw.include?("35.0 mm f/1.8")
              tagsToAdd = 'lens:maker=Nikon,lens:aperture=1.8,lens:focallength=35,"lens:type=AF-S DX Nikkor 35mm 1:1.8G"'
            elsif tag.raw.include?("85.0 mm f/1.8")
              tagsToAdd = 'lens:maker=Nikon,lens:aperture=1.8,lens:focallength=85,"lens:type=AF Nikkor 85mm 1:1.8D"'
            elsif tag.raw.include?("50.0 mm f/1.8")
              tagsToAdd = 'lens:maker=Nikon,lens:aperture=1.8,lens:focallength=50,"lens:type=AF Nikkor 50mm 1:1.8D"'
            elsif tag.raw.include?("55-200mm f/4-5.6")
              tagsToAdd = 'lens:maker=Nikon,lens:aperture=4.0-5.6,lens:focallength=55-200,"lens:type=AF-S DX Zoom-Nikkor 55-200mm 1:4-5.6 G IF-ED VR"'
            end
            break

          end

        end

      end

      if tagsToAdd
        flickr.photos.addTags :photo_id => photo.id, :tags => tagsToAdd
      else
        puts "  Unknown lens"
        exif.exif.each do |tag|
          if tag.tag.include?("Lens")
            puts "    #{tag.tag} => #{tag.raw}"
          end
        end
      end

    end

    if page == allUserPhotos.pages
      stop = true
    end
    page = page + 1
  end

end
