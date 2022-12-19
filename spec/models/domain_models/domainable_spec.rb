# frozen_string_literal: true

require 'rails_helper'

shared_examples_for 'domainable' do
  let(:model) { described_class } # the class that includes the concern
  let(:model_klass) { subject } # the class that includes the concern

  it 'has an id attribute' do
    expect(model.new.id).not_to be_nil
  end

  it 'runs attributes through the contract' do
    binding.pry
    model.validate_values
  end
end

# RSpec.describe DomainModels::Domainable do
#   context 'One-to-many Association' do
#     let(:customer_klass) do
#       Class.new do
#         include Mongoid::Document
#         include DomainModels::Domainable

#         # has_many :orders, class_name: 'Ns1::Ns2::Order'
#         has_many :orders, class_name: 'DummyOrder'

#         field :name, type: String
#       end
#     end

#     let(:order_klass) do
#       Class.new do
#         include Mongoid::Document
#         include DomainModels::Domainable

#         # belongs_to :customer, class_name: 'Ns1::Ns2::Customer'
#         belongs_to :customer, class_name: 'DummyCustomer'

#         field :item_name, type: String
#         field :item_count, type: Integer
#       end
#     end

#     before do
#       # stub_const('Ns1::Ns2::Customer', customer)
#       # stub_const('Ns1::Ns2::Order', order)
#       stub_const('DummyCustomer', customer_klass)
#       stub_const('DummyOrder', order_klass)
#     end

#     let(:name) { 'George Jetson' }
#     let(:pencil_order) { { item_name: 'Pencil', item_count: 6 } }
#     let(:notepad_order) { { item_name: 'Notepad', item_count: 2 } }

#     # let(:customer) { Customer.new(name: name, orders: [pencil_order, notepad_order]) }

#     it 'should instantiate a class' do
#       binding.pry
#       customer = DummyCustomer.new(name: name)
#       customer.orders.build(pencil_order)
#       # expect(customer).to be_a(Ns1::Ns2::Customer)
#     end
#   end
# end
