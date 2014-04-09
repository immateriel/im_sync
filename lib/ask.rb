
class Ask
  attr_accessor :doc

#  @@ask_check_url="http://localhost:3000/fr/web_service/ask_check"
#  @@ask_push_url="http://localhost:3000/fr/web_service/ask_push"

  @@ask_check_url="https://ws.immateriel.fr/fr/web_service/ask_check"
  @@ask_push_url="https://ws.immateriel.fr/fr/web_service/ask_push"

  def initialize
    @doc=IMML::Document.new
    @doc.header=IMML::Header::Header.create
  end

  def test_ident(receive_url,check_url)
    @doc.header.test=IMML::Header::Test.create(receive_url,check_url,nil)
  end

  def ident(api_key,reseller_id,reseller_gencod)
    @doc.header.authentication=IMML::Header::Authentication.create(api_key)
    if reseller_id
      @doc.header.reseller=IMML::Header::Reseller.create(reseller_id)
    else
      if reseller_gencod
        @doc.header.reseller=IMML::Header::Reseller.create(nil,reseller_gencod)
      end
    end
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