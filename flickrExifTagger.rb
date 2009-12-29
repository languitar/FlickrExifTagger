
require "flickraw"
require "optparse"

API_KEY = "25de6f1217a9f614e8782481d0e6ea99"
SHARED_SECRET = "4401b29a4e0ca1df"

$login = nil

def doLogin
  
  FlickRaw.api_key = API_KEY
  FlickRaw.shared_secret = SHARED_SECRET
  
  # login the manual way without an old frob
  
  frob = flickr.auth.getFrob()
  authUrl = FlickRaw.auth_url :frob => frob, :perms => 'write'
  
  puts("Open this url in your process to complete the authication process : #{authUrl}")
  puts("Press Enter when you are finished.")
  STDIN.getc

  
  begin
    token = flickr.auth.getToken :frob => frob
    $login = flickr.test.login
    puts("You are now authenticated as #{$login.username}")
  rescue FlickRaw::FailedResponse => e
    puts("Authentication failed : #{e.msg}")
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
      exif.exif.each do |tag|
        begin
          if tag.tag == "LensType"
            
            puts("\tLens is: #{tag.raw}")
            
            tagsToAdd = nil
            if tag.raw.include?("14-42mm")
              tagsToAdd = "lens:maker=Olympus,lens:aperture=3.5-5.6,lens:focallength=14-42,\"lens:type=Zuiko Digital ED 14-42mm F3.5-5.6\""
            elsif tag.raw.include?("40-150mm")
              tagsToAdd = "lens:maker=Olympus,lens:aperture=4.0-5.6,lens:focallength=40-150,\"lens:type=Zuiko Digital ED 40-150mm F4.0-5.6\""
            elsif tag.raw.include?("(1 22")
              tagsToAdd = "lens:maker=Sigma,lens:aperture=2.8,lens:focallength=70-200,\"lens:type=70-200mm F2.8 EX DG Makro HSM II\""
            elsif tag.raw.include?("35mm F3.5 Macro")
              tagsToAdd = "lens:maker=Olympus,lens:aperture=3.5,lens:focallength=35,\"lens:type=Zuiko Digital 35mm F3.5 Macro\""
            elsif tag.raw.include?("None")
              tagsToAdd = "lens:maker=Lensbaby,lens:focallength=50,\"lens:type=Lensbaby Muse Double Glass Optic\""
            end
            
            if tagsToAdd
              flickr.photos.addTags :photo_id => photo.id, :tags => tagsToAdd
              puts("\tadded tags: #{tagsToAdd}")
            end
            
            break
          end
        rescue NoMethodError => e
        end
      
      end
      
    end
    
    if page == allUserPhotos.pages
      stop = true
    end
    page = page + 1
  end
  
end
