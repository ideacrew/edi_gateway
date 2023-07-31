# frozen_string_literal: true

require 'nokogiri'

module Generators
  module Reports
    # SbmiXmlMerger is a class that merges multiple SBMI XML files into one
    class SbmiXmlMerger
      attr_reader :xml_docs
      attr_accessor :sbmi_folder_path, :calendar_year, :hios_prefix, :settings

      NS = {
        "xmlns" => "http://sbmi.dsh.cms.gov",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance"
      }.freeze

      def initialize(dir)
        @xml_docs = []
        @doc_count = nil
        @dir = dir
        @settings = YAML.safe_load(File.read("#{Rails.root}/config/irs_settings.yml")).with_indifferent_access
      end

      def process
        read
        merge
      end

      def read
        Dir.glob("#{@dir}/*.xml").each do |file_path|
          @xml_docs << Nokogiri::XML(File.open(file_path))
        end

        @doc_count = @xml_docs.count
        @xml_docs
      end

      def build_merged_xml
        consolidated_xml = Nokogiri::XML::Builder.new do |xml|
          xml.Enrollment(NS) do |en_xml|
            en_xml.FileInformation do
              en_xml.FileId "#{Time.now.utc.strftime('%Y%m%d%H%M%S')}#{hios_prefix}"
              en_xml.FileCreateDateTime Time.now.utc.iso8601
              en_xml.TenantId @settings[:cms_pbp_generation][:source_exchange_code]
              en_xml.CoverageYear calendar_year
              en_xml.IssuerFileInformation do
                en_xml.IssuerId hios_prefix
              end
            end
          end
        end

        consolidated_doc = consolidated_xml.doc

        consolidated_doc.xpath('//xmlns:Enrollment', NS).each do |node|
          @xml_docs.each do |xml_doc|
            xml_doc.remove_namespaces!
            new_node = xml_doc.xpath('//Policy').first
            node.add_child("#{new_node.to_xml(:indent => 2)}\n")
          end
        end

        consolidated_doc
      end

      # rubocop:disable Layout/LineLength
      def merge
        cms_pbp_source_sbm_id = settings[:cms_pbp_generation][:cms_pbp_source_sbm_id]
        file_name = "#{cms_pbp_source_sbm_id}.EPS.SBMI.D#{Time.now.utc.strftime('%y%m%d')}.T#{Time.now.utc.strftime('%H%M%S')}000.P.IN"
        @data_file_path = "#{sbmi_folder_path}/#{file_name}"

        File.write(@data_file_path, build_merged_xml.to_xml(:indent => 2))
      end
      # rubocop:enable Layout/LineLength

      def validate
        puts "processing...#{@data_file_path}"
        xsd = Nokogiri::XML::Schema(File.open("#{Rails.root}/SBMI.xsd"))
        doc = Nokogiri::XML(File.open(@data_file_path))

        xsd.validate(doc).each do |error|
          puts error.message
        end

        cross_verify_elements
      end

      def cross_verify_elements
        xml_doc = Nokogiri::XML(File.open(@data_file_path))

        element_count = xml_doc.xpath('//xmlns:Policy', NS).count
        if element_count == @doc_count
          puts "Element count looks OK!!"
        else
          puts "ERROR: Processed #{@doc_count} files...but got #{element_count} elements"
        end
      end
    end
  end
end
