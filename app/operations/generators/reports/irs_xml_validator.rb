# frozen_string_literal: true

module Generators
  module Reports
    # Validates a monthly IRS XML's
    class IrsXmlValidator
      attr_accessor :folder_path

      def initialize(folder_path)
        @folder_path = folder_path
      end

      def validate(_filename = nil, _type: :h36)
        Dir.foreach("#{@folder_path}/transmission") do |filename|
          next if (filename == '.') || (filename == '..') || (filename == 'manifest.xml') || (filename == '.DS_Store')

          xsd_file = "#{Rails.root}/HHS_ACA_XML_LIBRARY_10.1/MSG/HHS-IRS-MonthlyExchangePeriodicDataMessage-1.0.xsd"
          puts "processing...#{filename.inspect}"
          xsd = Nokogiri::XML::Schema(File.open(xsd_file))
          doc = Nokogiri::XML(File.open("#{@folder_path}/transmission/" + filename))

          xsd.validate(doc).each do |error|
            puts error.message
          end
        end
      end
    end
  end
end
