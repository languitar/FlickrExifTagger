# A hacky script to tag photos on flickr with lens machine tags based on
# information found in the image exif data.
#
# To be useful for you own set of lenses and camera you need to change the
# lines defining the tags to add based on the exif information found in the
# images (see comment below).
#
# This program is free software; you can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# @author: Johannes Wienke <languitar at semipol dot de>

API_KEY = '25de6f1217a9f614e8782481d0e6ea99'
SHARED_SECRET = '4401b29a4e0ca1df'

OLD_LOGIN_FILE = File.expand_path('~/.flickrexiftagger_login')

require 'flickraw'
require 'optparse'
require 'ostruct'
require 'yaml'
require 'pp'

FlickRaw.api_key = API_KEY
FlickRaw.shared_secret = SHARED_SECRET

$login = nil

def do_old_login
  fail 'No previous credentials available' unless File.file?(OLD_LOGIN_FILE)

  f = open(OLD_LOGIN_FILE, 'r')
  login_data = YAML.load(f.read())
  f.close

  flickr.access_token = login_data['token']
  flickr.access_secret = login_data['secret']

  $login = flickr.test.login
end

def do_login
  begin
    do_old_login
    return
  rescue StandardError => e
    puts "Using previous credentials failed: #{e}"
  end

  token = flickr.get_request_token
  auth_url = flickr.get_authorize_url(token['oauth_token'], perms: 'delete')

  puts 'Open this url in your process to complete the authication process: ' \
       "#{auth_url}"
  puts 'Copy here the number given when you complete the process.'
  verify = gets.strip

  begin
    flickr.get_access_token(token['oauth_token'],
                            token['oauth_token_secret'],
                            verify)
    $login = flickr.test.login
    puts "You are now authenticated as #{$login.username} " \
         "with token #{flickr.access_token} and secret #{flickr.access_secret}"
    f = open(OLD_LOGIN_FILE, 'w')
    f.write(YAML.dump('token' => flickr.access_token,
                      'secret' => flickr.access_secret))
    f.close
  rescue FlickRaw::FailedResponse => e
    puts "Authentication failed : #{e.msg}"
    exit(1)
  end
end

def parse_arguments(args)
  # provide defaults
  options = OpenStruct.new
  options.ignore_missing = false

  opt_parser = OptionParser.new do |opts|
    opts.on('-i', '--[no-]ignore-missing',
            'Ignore errors from missing rules and only print them during ' \
            'printing. Defaults to raising an error in case of ' \
            'a missing rule.') do |ignore|
      options.ignore_missing = ignore
    end
  end

  opt_parser.parse!(args)
  options
end

Matcher = Struct.new(:key, :regex)
Rule = Struct.new(:matchers, :tags)

$rules = [
  # Nikon camera
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /60\.0 ?mm f\/2\.8/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '2.8',
           'lens:focallength' => '60',
           'lens:type' => 'AF-S micro Nikkor 60mm/2.8G ED'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /10\.0-20\.0 ?mm f\/4\.0-5\.6/)],
           'lens:maker' => 'Sigma',
           'lens:aperture' => '4.0-5.6',
           'lens:focallength' => '10-20',
           'lens:type' => '10-20mm f4-5.6 EX DC HSM'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /90\.0 ?mm f\/2\.8/)],
           'lens:maker' => 'Tamron',
           'lens:aperture' => '2.8',
           'lens:focallength' => '90',
           'lens:type' => 'SP AF 90mm f/2.8 Di MACRO 1:1'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /16(\.0)?-85(\.0)? ?mm f\/3\.5-5\.6/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '3.5-5.6',
           'lens:focallength' => '16-85',
           'lens:type' => 'AF-S DX Nikkor 16-85mm 1:3.5-5.6G ED VR'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /70\.0-300\.0 ?mm f\/4\.0-5\.6/)],
           'lens:maker' => 'Tamron',
           'lens:aperture' => '4.0-5.6',
           'lens:focallength' => '70-300',
           'lens:type' => 'SP AF 70-300 F/4-5.6 Di VC USD'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /35(\.0)? ?mm f\/1\.8/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '1.8',
           'lens:focallength' => '35',
           'lens:type' => 'AF-S DX Nikkor 35mm 1:1.8G'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /85(\.0)? ?mm f\/1.8/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '1.8',
           'lens:focallength' => '85',
           'lens:type' => 'AF Nikkor 85mm 1:1.8D'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /50\.0 ?mm f\/1\.8/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '1.8',
           'lens:focallength' => '50',
           'lens:type' => 'AF Nikkor 50mm 1:1.8D'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /55(\.0)?-200(\.0)? ?mm f\/4-5.6/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '4.0-5.6',
           'lens:focallength' => '55-200',
           'lens:type' => 'AF-S DX Zoom-Nikkor 55-200mm 1:4-5.6 G IF-ED VR'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /18\.0-35\.0 mm f\/3\.5-4\.5/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '3.5-4.5',
           'lens:focallength' => '18-35',
           'lens:type' => 'AF-S Nikkor 18-35mm f/3.5-4.5G ED'),
  Rule.new([Matcher.new('exif.Make', /Nikon/i),
            Matcher.new('exif.Lens', /24\.0-120\.0 mm f\/4\.0/)],
           'lens:maker' => 'Nikon',
           'lens:aperture' => '4.0',
           'lens:focallength' => '24-120',
           'lens:type' => 'AF-S Nikkor 24-120mm f/4G ED VR'),
  # Olympus
  Rule.new([Matcher.new('exif.Make', /Olympus/i),
            Matcher.new('exif.LensType', /14-42mm/)],
           'lens:maker' => 'Olympus',
           'lens:aperture' => '3.5-5.6',
           'lens:focallength' => '14-42',
           'lens:type' => 'Zuiko Digital ED 14-42mm F3.5-5.6'),
  Rule.new([Matcher.new('exif.Lens', /Olympus/i),
            Matcher.new('exif.Lens', /14-42mm/)],
           'lens:maker' => 'Olympus',
           'lens:aperture' => '3.5-5.6',
           'lens:focallength' => '14-42',
           'lens:type' => 'Zuiko Digital ED 14-42mm F3.5-5.6'),
  Rule.new([Matcher.new('exif.Make', /Olympus/i),
            Matcher.new('exif.LensType', /40-150mm/)],
           'lens:maker' => 'Olympus',
           'lens:aperture' => '4.0-5.6',
           'lens:focallength' => '40-150',
           'lens:type' => 'Zuiko Digital ED 40-150mm F4.0-5.6'),
  Rule.new([Matcher.new('exif.Lens', /Olympus/i),
            Matcher.new('exif.Lens', /40-150mm/)],
           'lens:maker' => 'Olympus',
           'lens:aperture' => '4.0-5.6',
           'lens:focallength' => '40-150',
           'lens:type' => 'Zuiko Digital ED 40-150mm F4.0-5.6'),
  Rule.new([Matcher.new('exif.Make', /Olympus/i),
            Matcher.new('exif.LensType', /1 22/)],
           'lens:maker' => 'Sigma',
           'lens:aperture' => '2.8',
           'lens:focallength' => '70-200',
           'lens:type' => '70-200mm F2.8 EX DG Makro HSM II'),
  Rule.new([Matcher.new('exif.Make', /Olympus/i),
            Matcher.new('exif.LensType', /35mm F3\.5 Macro/)],
           'lens:maker' => 'Olympus',
           'lens:aperture' => '3.5',
           'lens:focallength' => '35',
           'lens:type' => 'Zuiko Digital 35mm F3.5 Macro'),
  Rule.new([Matcher.new('exif.Make', /Olympus/i),
            Matcher.new('exif.LensType', /Sigma 10-20mm/)],
           'lens:maker' => 'Sigma',
           'lens:aperture' => '4.0-5.6',
           'lens:focallength' => '10-20',
           'lens:type' => '10-20mm F4-5.6 EX DC HSM'),
  Rule.new([Matcher.new('exif.Make', /Olympus/i),
            Matcher.new('exif.LensType', /None/)],
           'lens:maker' => 'Lensbaby',
           'lens:focallength' => '50',
           'lens:type' => 'Lensbaby Muse Double Glass Optic'),
  # Ignore Nexus 5
  Rule.new([Matcher.new('exif.Make', /LGE/i),
            Matcher.new('exif.Model', /Nexus 5/)],
           nil),
  # Ignore RX100
  Rule.new([Matcher.new('exif.Make', /Sony/i),
            Matcher.new('exif.Model', /DSC-RX100M2/)],
           nil)
]

def handle_missing(mapped_tags, ignore_missing)
  debug_string = Hash[mapped_tags.sort()].pretty_inspect
  if ignore_missing
    puts '  Unknown lens'
    puts debug_string
  else
    fail "Unknown lens:\n#{debug_string}"
  end
end

def match_rule(rules, mapped_tags)
  rules.each do |rule|
    # find out whether this rules matches
    matches = true
    rule.matchers.each do |matcher|
      matches &= matcher.regex.match(mapped_tags[matcher.key])
    end

    # if we have a matching rule, use the first one and ignore all others
    return rule if matches
  end
  fail 'No matching rule found'
end

if __FILE__ == $PROGRAM_NAME
  options = parse_arguments(ARGV)

  do_login()

  # iterate through all photo pages
  stop = false
  page = 0
  until stop
    all_user_photos = flickr.photos.search user_id: $login.id, page: page
    puts("Going through page #{page} of #{all_user_photos.pages} " \
         "with #{all_user_photos.perpage} photos per page")

    all_user_photos.each do |photo|
      info = flickr.photos.getInfo photo_id: photo.id, secret: photo.secret
      puts("processing photo #{info.title}")

      exif = flickr.photos.getExif photo_id: photo.id, secret: photo.secret

      # create a hash for all tags
      mapped_tags = {}
      exif.exif.each do |tag|
        mapped_tags["exif.#{tag.tag}"] = tag.raw
      end

      begin
        rule = match_rule($rules, mapped_tags)
        tags_to_add = rule.tags
        tags_to_add = tags_to_add.map{|k,v| "\"#{k}=#{v}\""}.join(',') \
          if tags_to_add
        puts "  #{tags_to_add}"
        flickr.photos.addTags photo_id: photo.id, tags: tags_to_add \
          if tags_to_add
      rescue RuntimeError
        handle_missing(mapped_tags, options.ignore_missing)
      end
    end

    stop = page == all_user_photos.pages
    page += 1
  end
end
