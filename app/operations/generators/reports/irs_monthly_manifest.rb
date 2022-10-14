# frozen_string_literal: true

module Generators
  module Reports
    # Creates a IRS Monthly Manifest
    class IrsMonthlyManifest
      NS = {
        "xmlns:ns1" => "http://niem.gov/niem/structures/2.0",
        "xmlns:ns2" => "http://hix.cms.gov/0.1/hix-core",
        "xmlns:ns4" => "http://birsrep.dsh.cms.gov/extension/1.0",
        "xmlns:ns3" => "http://niem.gov/niem/niem-core/2.0",
        "xmlns:ns5" => "http://birsrep.dsh.cms.gov/exchange/1.0"
      }.freeze

      def create(folder)
        @folder = folder
        @manifest = OpenStruct.new({
                                     file_count: Dir.glob("#{@folder}/*.xml").count
                                   })
        manifest_xml = serialize.to_xml(:indent => 2)
        File.open("#{folder}/manifest.xml", 'w') do |file|
          file.write manifest_xml
        end
      end

      def serialize
        Nokogiri::XML::Builder.new do |builder_xml|
          builder_xml['ns5'].BatchHandlingServiceRequest(NS) do |batch_xml|
            serialize_batch_data(batch_xml)
            serialize_transmission_data(batch_xml)
            serialize_service_data(batch_xml)
            attachments.each do |attachment|
              serialize_attachment(batch_xml, attachment)
            end
          end
        end
      end

      def attachments
        Dir.glob("#{@folder}/*.xml").inject([]) do |data, file|
          data << OpenStruct.new({
                                   checksum: Digest::SHA256.file(file).hexdigest,
                                   binarysize: File.size(file),
                                   filename: File.basename(file),
                                   sequence_id: File.basename(file).match(/\d{5}/)[0]
                                 })
        end
      end

      def serialize_batch_data(batch_xml)
        batch_xml['ns2'].BatchMetadata do |xml|
          xml.BatchID Time.now.utc.iso8601
          xml.BatchPartnerID '02.ME*.SBE.001.001'
          xml.BatchAttachmentTotalQuantity @manifest.file_count
          xml['ns4'].BatchCategoryCode 'IRS_EOM_IND_REQ'
          xml.BatchTransmissionQuantity 1
        end
      end

      def serialize_transmission_data(batch_xml)
        batch_xml['ns2'].TransmissionMetadata do |xml|
          xml.TransmissionAttachmentQuantity @manifest.file_count
          xml.TransmissionSequenceID 1
        end
      end

      def serialize_service_data(batch_xml)
        batch_xml['ns4'].ServiceSpecificData do |ssd_xml|
          ssd_xml.ReportPeriod do |xml|
            xml['ns3'].YearMonth Date.today.prev_month.strftime("%Y-%m")
          end
        end
      end

      def serialize_attachment(batch_xml, file)
        batch_xml['ns4'].Attachment do |attachment_xml|
          attachment_xml['ns3'].DocumentBinary do |db_xml|
            serialize_binary(db_xml)
          end
          attachment_xml['ns3'].DocumentFileName file.filename
          attachment_xml['ns3'].DocumentSequenceID file.sequence_id
        end
      end

      def serialize_binary(db_xml)
        db_xml['ns2'].ChecksumAugmentation do |xml|
          xml['ns4'].SHA256HashValueText file.checksum
        end
        db_xml['ns2'].BinarySizeValue file.binarysize
      end
    end
  end
end
