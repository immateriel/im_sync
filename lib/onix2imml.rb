require 'im_onix'
require 'imml'

class Onix2Imml
  attr_accessor :imml_books

  def initialize
    @imml_books=[]
  end

  def parse_onix_file(filename)
    msg=ONIX::ONIXMessage.new
    msg.parse(filename)

    msg.products.each do |product|
      if product.sold_separately?

        imml_book=IMML::Book::Book.create(product.ean)

      imml_book.metadata=IMML::Book::Metadata.create(product.title,product.language_code_of_text,product.raw_description,product.subtitle,product.publication_date)
      imml_book.metadata.publisher=IMML::Book::Publisher.create(product.publisher_name)

      product.contributors.each do |c|
        imml_book.metadata.contributors << IMML::Book::Contributor.create(c.name,c.role.human.downcase)
      end

      imml_book.metadata.topics=IMML::Book::Topics.create

      product.bisac_categories_codes.each do |bcc|
        imml_book.metadata.topics << IMML::Book::Topic.create("bisac",bcc)
      end

      product.clil_categories_codes.each do |bcc|
        imml_book.metadata.topics << IMML::Book::Topic.create("clil",bcc)
      end

      product.keywords.each do |bcc|
        imml_book.metadata.topics << IMML::Book::Topic.create("keyword",bcc)
      end

      if product.publisher_collection_title
        imml_book.metadata.collection=IMML::Book::Collection.create(product.publisher_collection_title)
      end


      imml_book.assets=IMML::Book::Assets.create
      if product.frontcover_url
        mimetype=product.frontcover_mimetype
        unless mimetype
          case product.frontcover_url
            when /\.png$/
              mimetype="image/png"
            when /\.jpe?g$/
              mimetype="image/jpeg"
            when /\.gif$/
              mimetype="image/gif"
          end
        end
        imml_book.assets.cover=IMML::Book::Cover.create(mimetype,nil,product.frontcover_last_updated,nil,product.frontcover_url)
      end

      if product.epub_sample_url
        imml_book.assets.extracts << IMML::Book::Extract.create(product.epub_sample_mimetype,nil,product.epub_sample_last_updated,product.epub_sample_url)
      end

      if product.digital?
        if product.bundle?
          product.parts.each do |part|
            if part.file_mimetype
              imml_book.assets.fulls << IMML::Book::Full.create(part.file_mimetype,part.filesize)
            end
          end
        else
          imml_book.assets.fulls << IMML::Book::Full.create(product.file_mimetype,product.filesize)
        end

      end

#  pp product.supplies


        imml_book.offer=IMML::Book::Offer.create("digital",product.available?)
        if product.pages
          imml_book.offer.pagination=product.pages
        end

        product.supplies_with_default_tax.each do |supply|
          if supply[:currency]=="EUR"
            imml_book.offer.sales_start_at=IMML::Book::SalesStartAt.create(supply[:availability_date])
          end

          if supply[:available]
            current_price=product.current_price_amount_for(supply[:currency]).to_f/100.0
            imml_book.offer.prices << IMML::Book::Price.create(supply[:currency],current_price,supply[:territory].join(" "))
          end
        end

        if product.print_product
          imml_book.offer.alternatives << IMML::Book::Alternative.create(product.print_product.ean,"printed")
        end

        @imml_books << imml_book

      end

    end


  end


end