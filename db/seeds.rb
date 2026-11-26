puts "Cleaning database..."
# Children first, so foreign keys never block a delete
Message.destroy_all
Phrase.destroy_all
Visit.destroy_all
Place.destroy_all
User.destroy_all

# ===== Users =====
puts "Creating users..."

user_annie = User.create!(
  email: "annie@rails.com",
  password: "123123",
  level: 12,
  experience: User.experience_for_level(12)
)

user_paul = User.create!(
  email: "paul@rails.com",
  password: "123123",
  level: 6,
  experience: User.experience_for_level(6)
)

user_jon = User.create!(
  email: "jon@rails.com",
  password: "123123",
  level: 8,
  experience: User.experience_for_level(8)
)

user_yoshi = User.create!(
  email: "yoshi@rails.com",
  password: "123123",
  level: 15,
  experience: User.experience_for_level(15)
)

puts "Created #{User.count} user(s)."

# ===== Places =====
require "httparty"
require "json"

puts "Fetching places from Google Places API (New)..."

API_KEY = ENV.fetch("GOOGLE_API_BROWSER_KEY")

AREAS = ["Meguro", "Shibuya"]

SEARCHES = {
  "cafe" => "cafes",
  "combini" => "convenience stores",
  "ramen" => "ramen"
}

FIELD_MASK = %w[
  places.id
  places.displayName
  places.formattedAddress
  places.location
  places.primaryType
  places.editorialSummary
  places.photos
].join(",")

def search_places(query)
  response = HTTParty.post(
    "https://places.googleapis.com/v1/places:searchText",
    headers: {
      "Content-Type" => "application/json",
      "X-Goog-Api-Key" => API_KEY,
      "X-Goog-FieldMask" => FIELD_MASK
    },
    body: {
      textQuery: query,
      languageCode: "en",
      regionCode: "JP",
      pageSize: 5
    }.to_json
  )

  raise "Places API error: #{response.dig('error', 'message')}" unless response.success?

  response.fetch("places", [])
end

def photo_url_for(place)
  photo = place["photos"]&.first
  return nil unless photo

  response = HTTParty.get(
    "https://places.googleapis.com/v1/#{photo['name']}/media",
    query: { maxWidthPx: 800, skipHttpRedirect: true, key: API_KEY }
  )

  unless response.success?
    puts "photo failed: #{response.code}"
    return nil
  end

  response["photoUri"]
end

AREAS.each do |area|
  SEARCHES.each do |category, search_term|
    query = "#{search_term} in #{area}, Tokyo"
    puts "Searching: #{query}"

    search_places(query).each do |result|
      name = result.dig("displayName", "text")

      # find_or_initialize_by means a place found by two searches
      # (e.g. on the Meguro/Shibuya border) is only saved once
      place = Place.find_or_initialize_by(google_place_id: result["id"])
      place.assign_attributes(
        name: name,
        description: result.dig("editorialSummary", "text") || "#{name} is a #{category} in #{area}, Tokyo.",
        lat: result.dig("location", "latitude"),
        long: result.dig("location", "longitude"),
        address: result["formattedAddress"],
        category: category,
        minimum_level: place.minimum_level || rand(1..5),
        image_url: place.image_url || photo_url_for(result)
      )

      if place.save
        puts "  ✅ #{place.name}"
      else
        puts "  ❌ #{name}: #{place.errors.full_messages.join(', ')}"
      end
    end
  end
end

puts "Created #{Place.count} place(s)."

# ===== Visits =====
puts "Creating visits..."

# Coffee shops
visit_glitch = Visit.create!(
  user: user_annie,
  place: Place.where(category:"cafe").sample,
  self_rating: 5,
  status: "completed",
  prep: { goal: "Practiced ordering pour-over coffee in Japanese" }
)

visit_blue_bottle = Visit.create!(
  user: user_paul,
  place: Place.where(category:"cafe").sample,
  self_rating: 4,
  status: "completed",
  prep: { goal: "Learned how to order a matcha latte and an iced coffee" }
)

visit_fuglen = Visit.create!(
  user: user_jon,
  place: Place.where(category:"cafe").sample,
  self_rating: nil, # not finished yet
  status: "ready",
  prep: { goal: "Studied coffee-related vocabulary" }
)

# Restaurants
visit_ichiran = Visit.create!(
  user: user_yoshi,
  place: Place.where(category:"ramen").sample,
  self_rating: 5,
  status: "completed",
  prep: { goal: "Practiced ordering ramen and customizing toppings" }
)

visit_afuri = Visit.create!(
  user: user_annie,
  place: Place.where(category:"ramen").sample,
  self_rating: nil, # hasn't happened yet
  status: "active",
  prep: { goal: "Need to learn how to order yuzu ramen" }
)

# Convenience stores
visit_familymart = Visit.create!(
  user: user_paul,
  place: Place.where(category:"combini").sample,
  self_rating: 3,
  status: "completed",
  prep: { goal: "Practiced paying in cash and simple checkout phrases" }
)

visit_lawson = Visit.create!(
  user: user_jon,
  place: Place.where(category:"combini").sample,
  self_rating: 4,
  status: "completed",
  prep: { goal: "Learned how to ask for the total and pay by card" }
)

puts "Created #{Visit.count} visit(s)."

# ===== Phrases =====
puts "Creating phrases..."

# Glitch: pour-over
Phrase.create!(
  visit: visit_glitch,
  english: "Pour-over, please",
  japanese: "ハンドドリップでお願いします",
  romaji: "Hando dorippu de onegaishimasu"
)

Phrase.create!(
  visit: visit_glitch,
  english: "Which beans do you recommend?",
  japanese: "おすすめの豆はどれですか？",
  romaji: "Osusume no mame wa dore desu ka?"
)

# Blue Bottle: matcha latte + iced coffee
Phrase.create!(
  visit: visit_blue_bottle,
  english: "One matcha latte, please",
  japanese: "抹茶ラテを一つお願いします",
  romaji: "Matcha rate o hitotsu onegaishimasu"
)

Phrase.create!(
  visit: visit_blue_bottle,
  english: "Can I get an iced coffee?",
  japanese: "アイスコーヒーをいただけますか？",
  romaji: "Aisu koohii o itadakemasu ka?"
)

# Fuglen: coffee vocabulary
Phrase.create!(
  visit: visit_fuglen,
  english: "Hot, please",
  japanese: "ホットでお願いします",
  romaji: "Hotto de onegaishimasu"
)

# Ichiran: ordering + toppings
Phrase.create!(
  visit: visit_ichiran,
  english: "I'd like the ramen, please",
  japanese: "ラーメンをお願いします",
  romaji: "Raamen o onegaishimasu"
)

Phrase.create!(
  visit: visit_ichiran,
  english: "With extra chashu, please",
  japanese: "チャーシュー多めでお願いします",
  romaji: "Chaashuu oome de onegaishimasu"
)

# Afuri: yuzu ramen (planned)
Phrase.create!(
  visit: visit_afuri,
  english: "Yuzu-salt ramen, please",
  japanese: "柚子塩らーめんをお願いします",
  romaji: "Yuzu shio raamen o onegaishimasu"
)

Phrase.create!(
  visit: visit_afuri,
  english: "This one, please",
  japanese: "これをお願いします",
  romaji: "Kore o onegaishimasu"
)

# FamilyMart: paying cash + checkout
Phrase.create!(
  visit: visit_familymart,
  english: "Cash, please",
  japanese: "現金でお願いします",
  romaji: "Genkin de onegaishimasu"
)

Phrase.create!(
  visit: visit_familymart,
  english: "I don't need a bag",
  japanese: "袋はいりません",
  romaji: "Fukuro wa irimasen"
)

Phrase.create!(
  visit: visit_familymart,
  english: "Please heat it up",
  japanese: "温めてください",
  romaji: "Atatamete kudasai"
)

# Lawson: asking the total + paying by card
Phrase.create!(
  visit: visit_lawson,
  english: "How much is it?",
  japanese: "いくらですか？",
  romaji: "Ikura desu ka?"
)

Phrase.create!(
  visit: visit_lawson,
  english: "Can I pay by card?",
  japanese: "カードで払えますか？",
  romaji: "Kaado de haraemasu ka?"
)

Phrase.create!(
  visit: visit_lawson,
  english: "Thank you (after paying)",
  japanese: "ありがとうございました",
  romaji: "Arigatou gozaimashita"
)

puts "Created #{Phrase.count} phrase(s)."

# ===== Reviews =====
# Completed visits were already reviewed: mark their phrases used and record
# the XP they granted, so they can't be reviewed (and rewarded) again.
# Users' experience was set above, so no XP is added here.
puts "Adding review data to completed visits..."
Visit.completed.find_each do |visit|
  visit.phrases.update_all(used: true)
  visit.confidence = 4
  visit.experience_awarded = visit.visit_experience + visit.phrase_experience(visit.phrases.count)
  visit.save!
end

puts "Done!"
