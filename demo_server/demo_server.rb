require 'rack/request'
require 'rack/response'
require 'imml'
require 'csv'

class CsvDatabaseBook
  attr_accessor :ean, :title, :description, :authors, :publisher, :available, :price

  def server_url
    "http://youripaddress:9292/"
  end

  def download_file(url, local)
    system("wget #{url} -O #{local}")
  end

  def from_imml_book(imml_book)
    @ean=imml_book.ean
    @title=imml_book.metadata.title
    @authors=imml_book.metadata.contributors.map { |c| c.name }
    @description=imml_book.metadata.description
    @publisher=imml_book.metadata.publisher.name
    @price=imml_book.offer.prices_with_currency["EUR"].current_amount
    @available=imml_book.offer.ready_for_sale

    self.download_file(imml_book.assets.cover.url, "database/#{@ean}.png")
    system("convert database/#{@ean}.png -resize 16384@ database/#{@ean}.tiny.png")

    if imml_book.assets.extracts.first
      self.download_file(imml_book.assets.extracts.first.url, "database/#{@ean}.epub")
    end

  end

  def to_imml_book
    imml_book=IMML::Book::Book.create(@ean)
    imml_book.metadata=IMML::Book::Metadata.create(@title, "fre", @description)
    @authors.each do |a|
      imml_book.metadata.contributors << IMML::Book::Contributor.create(a, "author")
    end
    imml_book.metadata.publisher=IMML::Book::Publisher.create(@publisher)
    imml_book.assets=IMML::Book::Assets.create
    imml_book.assets.cover=IMML::Book::Cover.create("image/png", nil, nil, nil, self.cover_url)
    extract=IMML::Book::Extract.create("application/epub+zip", nil)
    extract.set_checksum("database/#{@ean}.epub")
    imml_book.assets.extracts << extract

    imml_book.offer=IMML::Book::Offer.create("digital", @available)
    imml_book.offer.prices << IMML::Book::Price.create("EUR", @price, "WORLD")
    imml_book
  end

  def cover_url
    "#{server_url}cover/#{@ean}.tiny.png"
  end

  def exists_in_database?
    File.exists?("database/#{@ean}.txt")
  end

  def from_database(ean)
    @ean=ean
    if self.exists_in_database?
      CSV.foreach("database/#{@ean}.txt") do |row|
        @title=row[0]
        @authors=row[1].split(",")
        @description=row[2]
        @publisher=row[3]
        @price=row[4].to_f
        @available=(row[5] == "true" ? true : false)
      end
      true
    else
      false
    end
  end

  def to_database
    CSV.open("database/#{@ean}.txt", "wb") do |csv|
      csv << [@title, @authors.join(","), @description, @publisher, @price, @available]
    end
  end

  # AR like
  def self.find(ean)
    b=self.new
    if b.from_database(ean)
      b
    end
  end

  def save
    self.to_database
  end
end

module Rack
  class DemoServer

    def immateriel_ip
      "77.247.182.210"
    end

    def call(env)
      req = Request.new(env)
      res = Response.new
      case req.path
        # simple product page
        when /^\/book\/.*/
          ean=req.path.gsub(/\/book\/(.*)$/, '\1')
          book=CsvDatabaseBook.find(ean)
          if book
            res.status=200
            res.write("<html>")
            res.write("<head>")
            res.write("<title>#{book.title}</title>")
            res.write('<meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>')
            res.write("</head>")
            res.write("<body>")
            res.write("<img src='#{book.cover_url}' align='left'/>")
            res.write("<h1>#{book.title}</h1>")
            res.write("<h2>#{book.authors.join(", ")}</h2>")
            res.write("<h3>#{book.publisher}</h3>")
            res.write("<div>#{book.description}</div>")
            res.write("<div><strong>#{book.price} euros</strong></div>")
            res.write("</body>")
            res.write("</html>")
          else
            res.status=404
            res.write("Book not found")
          end
        # cover URL
        when /^\/cover\/.*\.png/
          path=req.path.gsub(/\/cover\/(.*)$/, '\1')
          res['Content-Type'] = 'image/png'
          res.write ::File.read("database/#{path}")
          res.status=200
        # receive URL for web services
        when /^\/receive\/?$/
          # only for immatériel.fr
          if req.ip == self.immateriel_ip
            doc=IMML::Document.new
            body=req.body.read
            puts "REQUEST:"
            puts body
            doc.parse_data(body, false)

            book=CsvDatabaseBook.new
            book.from_imml_book(doc.book)
            book.save

            res.status=200
            puts "RESPONSE:"
            puts "OK"
            res.write("OK")
          else
            res.status=403
            res.write("Unauthorized")
          end
        # check URL for web services
        when /^\/check\/?$/
          # only for immatériel.fr
          if req.ip == self.immateriel_ip
            doc=IMML::Document.new
            body=req.body.read
            puts "REQUEST:"
            puts body

            doc.parse_data(body, false)

            book_param=doc.header.params.select { |p| p.name=="book" }.first
            if book_param
              book=CsvDatabaseBook.find(book_param.value)
              if book
                rdoc=IMML::Document.new
                rdoc.book=book.to_imml_book
                res.status=200
                puts "RESPONSE:"
                puts rdoc.to_xml
                res.write(rdoc.to_xml)
              else
                res.status=404
                res.write("Book not found")
              end
            else
              res.status=400
              res.write("KO")
            end
          else
            res.status=403
            res.write("Unauthorized")
          end

        else
          res.status=404
          res.write("Page not found")
      end
      res.finish
    end
  end
end