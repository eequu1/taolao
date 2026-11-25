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
  level: 3
)

user_paul = User.create!(
  email: "paul@rails.com",
  password: "123123",
  level: 2
)

user_jon = User.create!(
  email: "jon@rails.com",
  password: "123123",
  level: 2
)

user_yoshi = User.create!(
  email: "yoshi@rails.com",
  password: "123123",
  level: 2
)

puts "Created #{User.count} user(s)."

# ===== Places =====
puts "Creating places..."

# Coffee shops
place_glitch = Place.create!(
  name: "Glitch Coffee & Roasters",
  description: "Specialty coffee shop in Jimbocho famous for light-roast single-origin pour-over",
  lat: 35.6955,
  long: 139.7570,
  minimum_level: 2,
  image_url: "https://coffeeryokou.com/wp-content/uploads/2022/01/glitch-exterior.jpg"
)

place_blue_bottle = Place.create!(
  name: "Blue Bottle Coffee Aoyama",
  description: "Popular California-born specialty coffee chain with stylish space in Aoyama",
  lat: 35.6653,
  long: 139.7139,
  minimum_level: 2,
  image_url: "https://dynamic-media-cdn.tripadvisor.com/media/photo-o/12/a7/ac/2e/blue-bottle-coffee-aoyama.jpg"
)

place_fuglen = Place.create!(
  name: "Fuglen Tokyo",
  description: "Norwegian-style specialty coffee shop and cocktail bar in Tomigaya",
  lat: 35.6666,
  long: 139.6924,
  minimum_level: 2,
  image_url: "https://deeptokyo.jp/wp-content/uploads/2025/09/PC_IMG_4870-scaled.jpg"
)

# Restaurants
place_ichiran = Place.create!(
  name: "Ichiran Ramen Shibuya",
  description: "Famous individual booth tonkotsu ramen restaurant, open 24 hours",
  lat: 35.6611,
  long: 139.7010,
  minimum_level: 2,
  image_url: "https://tfp-group.co.jp/japan-spot-guide/assets/tokyo/shibuya/ichiran-ramen.jpg"
)

place_afuri = Place.create!(
  name: "Afuri Ramen Ebisu",
  description: "Popular modern ramen shop known for yuzu-salt ramen",
  lat: 35.6467,
  long: 139.7102,
  minimum_level: 3,
  image_url: "https://static.wixstatic.com/media/1815be_847f9ba702894ea0ba10133711c107bd~mv2.jpg/v1/fill/w_980,h_735,al_c,q_85,usm_0.66_1.00_0.01,enc_auto/1815be_847f9ba702894ea0ba10133711c107bd~mv2.jpg"
)

# Convenience stores
place_familymart = Place.create!(
  name: "FamilyMart Shibuya Udagawa",
  description: "Convenient FamilyMart near Shibuya Crossing, open 24 hours",
  lat: 35.6610,
  long: 139.6980,
  minimum_level: 1,
  image_url: "https://photo2.idnfinancials.com/fly/idn/Familymart.jpg"
)

place_lawson = Place.create!(
  name: "Lawson Shibuya Center-gai",
  description: "Lawson convenience store in the heart of Shibuya, open 24 hours",
  lat: 35.6598,
  long: 139.7008,
  minimum_level: 1,
  image_url: "https://www.planmyjapan.com/wp-content/uploads/2024/05/lawson-1-1148x800.jpg"
)

puts "Created #{Place.count} place(s)."

# ===== Visits =====
puts "Creating visits..."

# Coffee shops
visit_glitch = Visit.create!(
  user: user_annie,
  place: place_glitch,
  self_rating: 5,
  status: "completed",
  prep: { goal: "Practiced ordering pour-over coffee in Japanese" }
)

visit_blue_bottle = Visit.create!(
  user: user_paul,
  place: place_blue_bottle,
  self_rating: 4,
  status: "completed",
  prep: { goal: "Learned how to order a matcha latte and an iced coffee" }
)

visit_fuglen = Visit.create!(
  user: user_jon,
  place: place_fuglen,
  self_rating: nil, # not finished yet
  status: "ready",
  prep: { goal: "Studied coffee-related vocabulary" }
)

# Restaurants
visit_ichiran = Visit.create!(
  user: user_yoshi,
  place: place_ichiran,
  self_rating: 5,
  status: "completed",
  prep: { goal: "Practiced ordering ramen and customizing toppings" }
)

visit_afuri = Visit.create!(
  user: user_annie,
  place: place_afuri,
  self_rating: nil, # hasn't happened yet
  status: "active",
  prep: { goal: "Need to learn how to order yuzu ramen" }
)

# Convenience stores
visit_familymart = Visit.create!(
  user: user_paul,
  place: place_familymart,
  self_rating: 3,
  status: "completed",
  prep: { goal: "Practiced paying in cash and simple checkout phrases" }
)

visit_lawson = Visit.create!(
  user: user_jon,
  place: place_lawson,
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
puts "Done!"
