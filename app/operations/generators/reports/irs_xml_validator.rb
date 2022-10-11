module Generators::Reports
  class IrsXmlValidator
    attr_accessor :folder_path

    def initialize(folder_path)
      @folder_path = folder_path
    end

    def validate(filename=nil, type: :h36)
      Dir.foreach("#{@folder_path}/transmission") do |filename|
        next if filename == '.' or filename == '..' or filename == 'manifest.xml' or filename == '.DS_Store'

        puts "processing...#{filename.inspect}"
        xsd = Nokogiri::XML::Schema(File.open("#{Rails.root.to_s}/HHS_ACA_XML_LIBRARY_10.1/MSG/HHS-IRS-MonthlyExchangePeriodicDataMessage-1.0.xsd"))
        doc = Nokogiri::XML(File.open("#{@folder_path}/transmission/" + filename))

        xsd.validate(doc).each do |error|
          puts error.message
        end
      end
    end
  end
end
