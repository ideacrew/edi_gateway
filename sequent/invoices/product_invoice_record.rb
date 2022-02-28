module Invoices
  class ProductInvoiceRecord < Sequent::ApplicationRecord
    self.table_name = "invoices_product_invoice_records"
  end
end