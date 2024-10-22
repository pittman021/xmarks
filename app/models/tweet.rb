class Tweet < ApplicationRecord
    belongs_to :author
    belongs_to :owner, class_name: 'User'  # Establish the relationship to the User
  
    validates :twitter_id, uniqueness: true
  end
  