class Book < ApplicationRecord

    belongs_to :user
    validates :title, :author, :reason, presence: true
end
