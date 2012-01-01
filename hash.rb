require 'bcrypt'

puts "Enter a password to hash:"
secret = gets.chomp()
@pw = BCrypt::Password.create(secret)
puts @pw
