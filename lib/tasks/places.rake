namespace :places do
  desc "Generate starter phrases for places that have none (FORCE=1 regenerates all). Calls OpenAI."
  task generate_phrases: :environment do
    places = ENV["FORCE"].present? ? Place.all : Place.where.missing(:place_phrases)
    places.find_each do |place|
      ok = PlacePhraseGenerator.call(place)
      puts "#{ok ? '✅' : '❌'} #{place.name} (#{place.place_phrases.count} phrases)"
    end
  end
end
