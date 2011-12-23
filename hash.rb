require 'bcrypt'

puts "Enter a string to hash:"
secret = gets.chomp()
@pw = BCrypt::Password.create(secret)
puts @pw

hash = "$2a$10$.5TFnyGgY5fXaGF3hyhU8eN5vMcHO5MOt1YfULyRschHsZ5aeoaqy"
@a = BCrypt::Password.new(hash)
if (@a == secret)
  puts "You pass"
end
