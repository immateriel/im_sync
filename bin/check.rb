require 'net/http'
require 'imml'

if ARGV[1] == nil
  puts "Usage: check.rb CHECK_SERVICE_URL BOOK_EAN"
  exit 1
end


uri = URI.parse(ARGV[0])
http = Net::HTTP.new(uri.host, uri.port)
request = Net::HTTP::Post.new(uri.request_uri)
request.body = '<?xml version="1.0"?>
<imml version="2.0">
  <header>
    <params>
      <param name="book" value="' + ARGV[1] + '"/>
    </params>
  </header>
</imml>'
response = http.request(request)

puts "Raw Output:"
puts "==============="
puts response.body
puts "==============="
puts ""
IMML::Document.new.parse_data(response.body)
