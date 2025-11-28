# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# 1. Clean the database 🗑️
puts "Cleaning database..."
User.destroy_all
Month.destroy_all
Event.destroy_all

# 2. Create the instances 🏗️
puts "Creating users..."
aurora = User.create!(email: "aurora@gmail.com", password: "123456", birthday: "1999-07-14")

# puts "Attaching user photos..."

# Commented the two lines below and one line above temporarily because the db:seed was not working!
# aurora_file = URI.parse("https://avatars.githubusercontent.com/u/236273565?v=4").open
# aurora.photo.attach(io: aurora_file, filename: "user.jpg", content_type: "image/jpg")

# 3. Display a message 🎉
puts "Created #{User.count} users."

puts "Creating months..."

start_month = Date.current.beginning_of_month
end_month   = (start_month + 30.years).end_of_month

current = start_month
total_assets = 100_000
saved_amount = 10_000

while current <= end_month
  Month.find_or_create_by!(
    date: current,
    user: aurora,
    total_assets: total_assets,
    saved_amount: saved_amount
  )

  total_assets += saved_amount

  current = current.next_month
end

# 3. Display a message 🎉
puts "Created #{Month.count} months."
