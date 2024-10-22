class BookRecommendationMailer < ApplicationMailer


    def weekly_recommendation(user, recommendations)
        @user = user
        @recommendations = recommendations
        
        mail(to:@user.email, subject: 'Your weekly book recommendations')
    end

end
