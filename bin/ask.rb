require 'rubygems'
require 'imml'
require 'net/http'
require 'net/https'

require 'optparse'

class Ask
  attr_accessor :doc

#  @@ask_check_url="http://localhost:3000/fr/web_service/ask_check"
#  @@ask_push_url="http://localhost:3000/fr/web_service/ask_push"

  @@ask_check_url="https://ws.immateriel.fr/fr/web_service/ask_check"
  @@ask_push_url="https://ws.immateriel.fr/fr/web_service/ask_push"

  def initialize(receive_url,check_url)
    @doc=IMML::Document.new
    @doc.header=IMML::Header::Header.create
    @doc.header.test=IMML::Header::Test.create(receive_url,check_url,nil)
    nil
  end

  def add_book_param(ean)
    @doc.header.params << IMML::Header::Param.create("book",ean)
  end

  def post(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    request = Net::HTTP::Post.new(uri.request_uri)
    request.body = @doc.xml_builder.to_xml
    response = http.request(request)
    if response.code.to_i/200 == 1
      true
    else
      false
    end
  end

  def ask_check
    self.post(@@ask_check_url)
  end
  def ask_push
    self.post(@@ask_push_url)
  end

end


@version="1.0.0"
@mode = nil
@check = nil
@receive = nil
@test = nil
@book = nil
@debug=false

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
@options.on('-b', '--book book', 'Book EAN') { |opt| @book = opt.strip }
@options.on('-d', '--debug',"Debug") {|opt| @debug=true}

@options.on_tail ""
@options.on_tail "Ask immateriel"

@options.parse(@arguments)

  case @mode
    when "receive"
      ask=Ask.new(@receive,@check)
      ask.add_book_param(@book)
      if @debug
        puts "SEND MESSAGE:"
        puts ask.doc.xml_builder.to_xml
      end
      ask.ask_push
    when "check"
      ask=Ask.new(@receive,@check)
      ask.add_book_param(@book)
      if @debug
        puts "SEND MESSAGE:"
        puts ask.doc.xml_builder.to_xml
      end
      ask.ask_check
    else
      puts "invalid mode"
  end

