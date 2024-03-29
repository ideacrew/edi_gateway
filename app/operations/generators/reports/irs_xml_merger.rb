# frozen_string_literal: true

require 'nokogiri'

module Generators
  module Reports
    # This class merges a monthly IRS XML's
    class IrsXmlMerger
      attr_reader :consolidated_doc, :xml_docs

      attr_accessor :irs_monthly_folder

      NS = {
        "xmlns" => "urn:us:gov:treasury:irs:common",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xmlns:n1" => "urn:us:gov:treasury:irs:msg:monthlyexchangeperiodicdata"
      }.freeze

      def initialize(dir, sequential_number)
        @dir = dir
        timestamp = "#{Time.now.utc.iso8601.gsub(/-|:/, '').match(/(.*)Z/)[1]}000Z"
        output_file_name = "EOM_Request_#{sequential_number}_#{timestamp}.xml"
        @data_file_path = File.join(@dir, '..', 'transmission', output_file_name)
        @xml_docs = []
        @doc_count = nil
        @consolidated_doc = nil
      end

      def process
        @xml_validator = Generators::Reports::IrsXmlValidator.new(@irs_monthly_folder.to_s)
        read
        merge
        write
        # reset_variables
      end

      def read
        Dir.glob("#{@dir}/*.xml").each do |file_path|
          @xml_docs << Nokogiri::XML(File.open(file_path))
        end
        @doc_count = @xml_docs.count
        @xml_docs
      end

      def merge
        if @consolidated_doc.nil?
          xml_doc = @xml_docs[0]
          xml_doc = chop_special_characters(xml_doc)
          @consolidated_doc = xml_doc
        end

        @xml_docs.shift

        @consolidated_doc.xpath('//xmlns:IndividualExchange', NS).each do |node|
          add_child_node(node)
        end

        @consolidated_doc
      end

      def add_child_node(node)
        @xml_docs.each do |xml|
          xml.remove_namespaces!
          new_node = xml.xpath('//IRSHouseholdGrp').first
          next if new_node.nil?

          new_node = chop_special_characters(new_node)
          node.add_child("#{new_node.to_xml(:indent => 2)}\n")
        end
      end

      def validate
        @xml_validator.validate(@data_file_path)
        cross_verify_elements
      end

      def cross_verify_elements
        xml_doc = Nokogiri::XML(File.open(@data_file_path))

        element_count = xml_doc.xpath('//xmlns:IRSHouseholdGrp', NS).count
        if element_count == @doc_count
          puts "Element count looks OK!!"
        else
          puts "ERROR: Processed #{@doc_count} files...but got #{element_count} elements"
        end
      end

      def write
        File.write(@data_file_path, @consolidated_doc.to_xml)
      end

      def self.validate_individuals(dir)
        Dir.glob("#{dir}/*.xml").each do |file_path|
          puts file_path.inspect
          @xml_validator.validate(file_path, type: :h36)
        end
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength

      def chop_special_characters(node)
        fetch_ssn(node)
        ["PersonFirstName", "PersonMiddleName", "PersonLastName", "AddressLine1Txt", "AddressLine2Txt", "CityNm"].each do |ele|
          node.xpath("//#{ele}", NS).each do |xml_tag|
            update_ele = ::Maybe.new(xml_tag.content).strip.gsub(/(-{2}|'|‘|’|\#|"|&|<|>)/, "").value
            if xml_tag.content.match(/(-{2}|'|‘|’|\#|"|&|<|>)/)
              puts xml_tag.content.inspect
              puts update_ele
            end

            if ele == "CityNm"
              update_ele = update_ele.gsub(/\s{2}/, ' ')
              update_ele = update_ele.gsub(/-/, ' ')
            end

            xml_tag.content = update_ele
          end
        end
        node
      end

      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      def fetch_ssn(node)
        node.xpath("//SSN", NS).each do |ssn_node|
          update_ssn = ::Maybe.new(ssn_node.content).strip.gsub("-", "").value
          ssn_node.content = update_ssn
        end
      end
    end
  end
end
