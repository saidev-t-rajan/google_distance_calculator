class Person < ActiveRecord::Base
  require 'csv'
  require 'net/http'
  API_KEY = Rails.env.production? ? ENV['GOOGLE_DISTANCE_API_KEY'] : GOOGLE_DISTANCE_API_KEY

  def self.calculate_distance( destination )
    all.each do |person|
      logger.info "Calculating for person #{person.id}: #{person.name}"

      if person.street_address.blank? && person.suburb.blank? && person.postcode.blank?
        logger.info " Address blank for person #{person.id}: #{person.name}"
      else
        escaped_origin = CGI.escape( "#{person.street_address} #{person.suburb} Australia #{person.postcode}" )
        escaped_destination = CGI.escape( "#{destination} Australia" )
        uri = URI(URI.encode("https://maps.googleapis.com/maps/api/distancematrix/json?origins=#{escaped_origin}&destinations=#{escaped_destination}&key=#{API_KEY}"))
        distance_hash = JSON.parse( Net::HTTP.get(uri) )

        logger.info "#{distance_hash}"

        if distance_hash['status'] == 'OK' && distance_hash['rows'].first['elements'].first['status'] == 'OK'
          person.destination = destination
          person.distance_meters = distance_hash['rows'].first['elements'].first['distance']['value']
          person.distance_text = distance_hash['rows'].first['elements'].first['distance']['text']
          person.duration_seconds = distance_hash['rows'].first['elements'].first['duration']['value']
          person.duration_text = distance_hash['rows'].first['elements'].first['duration']['text']

          person.save
        end
      end
    end
  end

	def self.import(file)
    if file
      CSV.foreach(file.path, headers: true) do |row|
        people_hash_csv = row.to_hash
        people_hash = { name:           people_hash_csv["Name"],
                        mrn:            people_hash_csv["MRN"],
                        street_address: people_hash_csv["Street Address"],
                        suburb:         people_hash_csv["Suburb"],
                        postcode:       people_hash_csv["Postcode"]
                      }

        unless people_hash[:mrn].blank?
          person = where(mrn: people_hash[:mrn])

          if person.count == 1
            person.first.update_attributes(people_hash)
          else
            create(people_hash)
          end
        end
      end
    end
  end

  def self.as_csv
    CSV.generate do |csv|
      csv << ['Name', 'MRN', 'Street Address', 'Suburb', 'Postcode', 'Destination', 'Distance(m)', 'Distance(text)', 'Time(secs)', 'Time(text)']
      all.each do |person|
        csv << person.attributes.slice('name', 'mrn', 'street_address', 'suburb', 'postcode', 'destination', 'distance_meters', 'distance_text', 'duration_seconds', 'duration_text').values
      end
    end
  end

  def self.average_distance
    ((Person.average( :distance_meters ) || 0) / 1000).round(3)
  end

  def self.average_time
    (Person.average( :duration_seconds ) || 0)
  end
end
