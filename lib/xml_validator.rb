require 'nokogiri'

class XmlValidator

  attr_accessor :folder_path

  def validate(filename=nil, type: :h36)
    Dir.foreach("#{@folder_path}/transmission") do |filename|
      # Dir.foreach("/Users/raghuram/DCHBX/gluedb/irs/h36_12_14_2015_11_38/transmission") do |filename|
      next if filename == '.' or filename == '..' or filename == 'manifest.xml' or filename == '.DS_Store'

      puts "processing...#{filename.inspect}"
    xsd = Nokogiri::XML::Schema(File.open("#{Rails.root.to_s}/HHS_ACA_XML_LIBRARY_10.1/MSG/HHS-IRS-MonthlyExchangePeriodicDataMessage-1.0.xsd"))

    doc = Nokogiri::XML(File.open("#{@folder_path}/transmission/" + filename))

    xsd.validate(doc).each do |error|
      # puts filename.inspect
      puts error.message
    end
  end
  end
end