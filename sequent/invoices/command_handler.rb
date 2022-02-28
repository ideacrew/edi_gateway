module Invoices
  class CommandHandler < Sequent::CommandHandler
    on ::Invoices::Commands::RequestProductInvoice do |command|
      repository.add_aggregate ::Invoices::ProductInvoice.new(command)
    end

    on ::Invoices::Commands::RecordProductInvoiceSpanCalculation do |command|
      repository.add_aggregate ::Invoices::CoverageSpanInvoiceEntrySet.new(command)
    end
  end
end