class Match < ActiveRecord::Base
  validates :tinder_id, uniqueness: true
end
