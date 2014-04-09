require 'rubygems'
require 'imml'
require 'net/http'
require 'net/https'

require 'optparse'
require 'ask'

@version="1.0.0"
@mode = nil
@check = nil
@receive = nil
@test = nil
@book = nil
@debug=false

@api_key=nil
@reseller_id=nil
@reseller_gencod=nil

@arguments=Array.new(ARGV)

@options = OptionParser.new
@options.banner = "Usage: ask.rb [options ...]"

@options.separator ""
@options.separator "Options :"

@options.on('-h', '--help', 'Display this help') { puts @options; exit }
@options.on('-v', '--version', 'Display version') { puts @version }

@options.separator ""

@options.separator "Main options :"
@options.on('-m', '--mode mode', 'Ask mode, check or receive') { |opt| @mode = opt }
@options.on('-c', '--check http://check_url', 'Check URL for test') { |opt| @check = opt }
@options.on('-r', '--receive http://receive_url', 'Receive URL for test') { |opt| @receive = opt }
@options.on('-u', '--api_key KEY', 'API key') { |opt| @api_key = opt }
@options.on('-i', '--reseller_id ID', 'Reseller ID') { |opt| @reseller_id = opt }
@options.on('-g', '--reseller_gencod GENCOD', 'Reseller Dilicom Gencod') { |opt| @reseller_gencod = opt }
@options.on('-b', '--book book', 'Book EAN') { |opt| @book = opt.strip }
@options.on('-d', '--debug', "Debug") { |opt| @debug=true }

@options.on_tail ""
@options.on_tail "Ask immateriel"

@options.parse(@arguments)

if @check or @receive
  @test=true
end

if @mode and ["receive", "check"].include?(@mode)
  @ask=Ask.new
  if @test
    @ask.test_ident(@receive, @check)
  else
    if @api_key and (@reseller_id or @reseller_gencod)
      @ask.ident(@api_key, @reseller_id, @reseller_gencod)
    else
      puts "ERROR: invalid identification"
    end
  end

  case @mode
    when "receive"
      @ask.add_book_param(@book)
      if @debug
        puts "SEND MESSAGE:"
        puts @ask.doc.to_xml
      end
#      @ask.ask_push
    when "check"
      @ask.add_book_param(@book)
      if @debug
        puts "SEND MESSAGE:"
        puts @ask.doc.to_xml
      end
#      @ask.ask_check
  end

else
  puts "ERROR: invalid mode"
end

