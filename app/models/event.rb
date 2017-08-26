class Event < ApplicationRecord
  belongs_to :result
  belongs_to :category, optional: true
end
