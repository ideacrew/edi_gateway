namespace :data do
  desc "Test an initial invoice"
  task :test_initial_invoice => :environment do
    records = ::Policies::PolicyRecord.select(:product_hios_id, :product_coverage_year).distinct.pluck(:product_hios_id, :product_coverage_year)
    records.each do |record|      
      request_invoice_command = ::Invoices::Commands::RequestProductInvoice.create(
        record.first,
        record.second,
        DateTime.new(2022,1,1,0,0,0,0),
        DateTime.new(2022,2,28,0,0,0,0)
      )
      Sequent.command_service.execute_commands request_invoice_command
    end
  end
end