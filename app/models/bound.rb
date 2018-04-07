class Bound < ApplicationRecord
  belongs_to :sensor
  # If 'sensor' is not valid, then bound will not be valid, also.
  validates_associated :sensor
end
