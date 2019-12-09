# frozen_string_literal: true

require 'common/client/base'
require 'gi/configuration'
require 'gi/responses/gi_response'

module GI
  # Core class responsible for api interface operations
  class Client < Common::Client::Base
    configuration GI::Configuration

    def get_institution_autocomplete_suggestions(params = {})
      gi_response(perform(:get, 'institutions/autocomplete', params, nil))
    end

    def get_institution_program_autocomplete_suggestions(params = {})
      gi_response(perform(:get, 'institution_programs/autocomplete', params, nil).body)
    end

    def get_calculator_constants(params = {})
      gi_response(perform(:get, 'calculator/constants', params, nil).body)
    end

    def get_institution_search_results(params = {})
      gi_response(perform(:get, 'institutions', params, nil).body)
    end

    def get_institution_program_search_results(params = {})
      gi_response(perform(:get, 'institution_programs', params, nil).body)
    end

    def get_institution_details(params = {})
      facility_code = params[:id]
      gi_response(perform(:get, "institutions/#{facility_code}", params.except(:id), nil).body)
    end

    def get_institution_children(params = {})
      facility_code = params[:id]
      gi_response(perform(:get, "institutions/#{facility_code}/children", params.except(:id), nil).body)
    end

    def get_zipcode_rate(params = {})
      zipcode = params[:id]
      gi_response(perform(:get, "zipcode_rates/#{zipcode}", {}, nil).body)
    end

    private

    def gi_response(response)
      GI::Responses::GiResponse.with_body(response)
    end
  end
end
