require 'rack'
require './luggage'
Luggage.create

map '/share' do
  run Luggage
end
