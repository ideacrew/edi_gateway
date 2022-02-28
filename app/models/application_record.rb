# frozen_string_literal: true

# Rails convention for ActiveRecord abstraction
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end
