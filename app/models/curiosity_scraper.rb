class CuriosityScraper
  BASE_URL = "https://mars.jpl.nasa.gov/msl/multimedia/raw/"

  attr_reader :rover
  def initialize
    @rover = Rover.find_by(name: "Curiosity")
  end

  def scrape
    create_photos
  end

  # grabs the HTML from the main page of the curiosity rover image gallery
  def main_page
    Nokogiri::HTML(open("https://mars.jpl.nasa.gov/msl/multimedia/raw/"))
  end

  def collect_links
    # collects link suffixes to pages for martian solar cycle from each camera
    main_page.css("div.image_list a").map { |link| link['href'] }.reject { |param_string|
      photos_exist_for_sol? param_string
    }
  end

  private

  def create_photos
    collect_links.each do |url|
      scrape_photo_page(url)
    end
  end

  def scrape_photo_page(url)
    image_page = Nokogiri::HTML(open(BASE_URL + url))
    image_array = image_page.css("div.RawImageCaption div.RawImageUTC a")
      .map { |link| link["href"] }
    image_array.each do |image|
      create_photo(image, url)
    end
  end

  def create_photo(image, url)
    if !thumbnail?(image)
      sol = url.scan(/(?<==)\d+/).first
      camera = camera_from_url url
      fail "Camera not found. Name: #{camera_name}" if camera.nil?
      photo = Photo.find_or_initialize_by(sol: sol, camera: camera,
                                          img_src: image, rover: rover)
      photo.log_and_save_if_new
    end
  end

  def thumbnail?(image_url)
    image_url.to_s.include?("_T")
  end

  def camera_from_url(url)
    camera_name = url.scan(/(?<=camera=)\w+/).first
    camera_name = "NAVCAM" if navcam_names.include? camera_name
    rover.cameras.find_by(name: camera_name)
  end

  def navcam_names
    ["NAV_LEFT", "NAV_RIGHT", "NAV"]
  end

  def photos_exist_for_sol?(param_string)
    sol = param_string.match(/s=(\d+)/)[1]
    rover.photos.where(sol: sol).any?
  end
end
