class User < ApplicationRecord
    pay_customer default_payment_processor: :stripe, stripe_attributes: :stripe_attributes
    has_many :books, dependent: :destroy
    has_many :tweets, foreign_key: 'owner_id'  # Specify the foreign key for ownership


    def email
        "#{nickname}@gmail.com"
    end

    def stripe_attributes(user)
        {
            metadata: {
                twitter_id: twitter_id,
                user_id: id,
                nickname: "@#{nickname}"
            }
        }
    end
end
    