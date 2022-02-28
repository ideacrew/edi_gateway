require "rails_helper"

describe ::Invoices::Commands::RequestProductInvoice, "given valid input" do
  it "fails" do
    request_invoice_command = ::Invoices::Commands::RequestProductInvoice.create(
      "132461-234",
      "2022",
      DateTime.new(2022,1,1,0,0,0,0),
      DateTime.new(2022,1,31,0,0,0,0)
    )
    Sequent.command_service.execute_commands request_invoice_command
  end
end