class Overflow < ApplicationRecord
  belongs_to :sensor
  # If 'sensor' is not valid, then overflow is not valid, also..
  validates_associated :sensor
end
