class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # UUIDs are random, so order by creation time for `.first` / `.last`.
  self.implicit_order_column = "created_at"
end
