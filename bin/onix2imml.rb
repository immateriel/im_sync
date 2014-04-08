require 'optparse'
require 'onix2imml'


@arguments=Array.new(ARGV)

@input=nil
@output=nil

@options = OptionParser.new
@options.banner = "Usage: ask.rb [options ...]"

@options.separator ""
@options.separator "Options :"

@options.on('-h', '--help', 'Display this help') { puts @options; exit }
@options.on('-v', '--version', 'Display version') { puts @version }

@options.separator ""

@options.separator "Main options :"
@options.on('-i', '--input in', 'ONIX input file') { |opt| @input = opt }
@options.on('-o', '--output out', 'IMML output prefix') { |opt| @output = opt }

@options.on_tail ""
@options.on_tail "immateriel ONIX 3 to IMML converter"

@options.parse(@arguments)

if @input and @output
  onix=Onix2Imml.new
  onix.parse_onix_file(@input)
  onix.imml_books.each do |b|
    filename="#{@output}_#{b.ean}.xml"
    doc=IMML::Document.new
    doc.book=b

    file=File.open(filename,'w')
    file.write doc.to_xml
    file.close
  end

end