# frozen_string_literal: true

require 'sidekiq'

module ClaimsApi
  class ClaimEstablisher
    include Sidekiq::Worker

    def perform(auto_claim_id)
      auto_claim = ClaimsApi::AutoEstablishedClaim.find(auto_claim_id)

      form_data = auto_claim.form.to_internal
      auth_headers = auto_claim.auth_headers

      response = service(auth_headers).submit_form526(form_data)

      auto_claim.evss_id = response.claim_id
      auto_claim.status = ClaimsApi::AutoEstablishedClaim::SUCCESS
      auto_claim.save
    end

    private

    def service(auth_headers)
      EVSS::DisabilityCompensationForm::ServiceAllClaim.new(
        auth_headers
      )
    end
  end
end
