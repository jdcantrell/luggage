require 'rack'
require './luggage'
Luggage.create

map '/luggage' do
  run Luggage
end
