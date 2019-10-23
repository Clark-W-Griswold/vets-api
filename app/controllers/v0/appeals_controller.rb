# frozen_string_literal: true

module V0
  class AppealsController < ApplicationController
    include ActionController::Serialization

    before_action { authorize :appeals, :access? }

    def index
      appeals_response = Appeals::Service.new.get_appeals(current_user)
      render(
        json: appeals_response.body
      )
    end

    def show
      service.get_higher_level_reviews params[:uuid]
      render json: higher_level_review
    end

    def intake_status
      intake_status = service.get_higher_level_reviews_intake_status params[:uuid]
      render json: intake_status
    end

    def create
      review = service.post_higher_level_reviews request.raw_post

      if review.accepted?
        HigherLevelReview.find_or_create_by claims_id: params[:claims_id], review_uuid: review.uuid
        render json: { 'status': 'ok' }
      else
        # Render errors here
      end
    end

    private

    def service
      DecisionReview::Service.new
    end
  end
end
