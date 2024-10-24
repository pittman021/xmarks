class CheckoutsController < ApplicationController
  before_action :require_user!
  
  def show
  end

  def create

    @checkout_session = current_user.payment_processor.checkout(
      mode: "payment",
      line_items: ENV['STRIPE_PRICE_ID'],
      allow_promotion_codes: true
    )

    redirect_to @checkout_session.url, allow_other_host: true, status: :see_other, notice: "Your purchase was a success! Enjoy!"
    
    # go to stripe checkout
  end


end
