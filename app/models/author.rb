class Author < ApplicationRecord
    has_many :tweets
  
    validates :twitter_id, uniqueness: true
  end
  