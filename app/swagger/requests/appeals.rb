# frozen_string_literal: true

module Swagger
  module Requests
    class Appeals
      include Swagger::Blocks

      swagger_path '/v0/appeals' do
        operation :get do
          extend Swagger::Responses::AuthenticationError

          key :description, 'returns list of appeals for a user'
          key :operationId, 'getAppeals'
          key :tags, %w[benefits_status]

          parameter :authorization

          response 200 do
            key :description,
                '200 passes the response from the upstream appeals API. Their swagger can be viewed here https://app.swaggerhub.com/apis/dsva-appeals/appeals-status/2.0.0#/default/appeals'
            schema do
              key :'$ref', :Appeals
            end
          end

          response 401 do
            key :description, 'User is not authenticated (logged in)'
            schema do
              key :'$ref', :Errors
            end
          end

          response 403 do
            key :description, 'Forbidden: user is not authorized for appeals'
            schema do
              key :'$ref', :Errors
            end
          end

          response 404 do
            key :description, 'Not found: appeals not found for user'
            schema do
              key :'$ref', :Errors
            end
          end

          response 422 do
            key :description, 'Unprocessable Entity: one or more validations has failed'
            schema do
              key :'$ref', :Errors
            end
          end

          response 502 do
            key :description, 'Bad Gateway: the upstream appeals app returned an invalid response (500+)'
            schema do
              key :'$ref', :Errors
            end
          end
        end
      end

      swagger_path '/v0/appeals/higher_level_reviews' do
        operation :post do
          key :operationId, 'postHigherLevelReview'
          key :tags, %w[higher_level_reviews]
          key :description, 'This endpoint will submit a Decision Review request of type Higher-Level Review.'\
                            'This endpoint is analogous to submitting VA For 20-0996 via mail or fax. ### '\
                            'Asynchronous processing The Decision Reviews API leverages a pattern recommended '\
                            'by JSON API for asynchronous processing (more information '\
                            '[here](https://jsonapi.org/recommendations/#asynchronous-processing)). Submitting '\
                            'a Decision Review is an asynchronous process due to the multiple systems that are '\
                            'involved. Because of this, when a new Decision Review is submitted, the POST '\
                            'endpoint will return a 202 `accepted` response including an Intake UUID. That '\
                            'Intake UUID is associated with the submission and can be used as an identifier '\
                            'for the Intake Status endpoint. While the submission is processing the Intake '\
                            'Status endpoint will return a 200 response. Once the asynchronous process is '\
                            'complete and the Decision Review is submitted into Caseflow, the Intake Status '\
                            'endpoint will return a 303 response including the Decision Review ID for the '\
                            'submitted Decision Review, which will allow you to retrieve the full details '\
                            'including the processing status.'
          
          parameter do
            schema do
              key :'$ref', :HigherLevelReviewParameters
            end
          end

          response 202 do
            key :description, 'Accepted'
            header 'Content-Location' do
              schema do
                key :type, :string
                key :format, :url
              end
              key :description, 'Link to check status of intake for HigherLevelReview'
            end
            content 'application/vnd.api+json' do
              schema do
                key :'$ref', :IntakeStatus
              end
            end
          end

          response 400 do
            key :description, 
          end
        end
      end

      swagger_path '/v0/appeals/higher_level_reviews/{uuid}' do
        operation :get do
          key :description, 'This endpoint returns the details of a specific Higher Level Review'
          key :operationId, 'showHigherLevelReview'
          key :tags, %w[higher_level_reviews]

          parameter do
            key :name, :uuid
            key :in, :path
            key :description, 'UUID of a higher level review'
            key :required, true

            schema do
              property :data,
                       type: :string,
                       format: :uuid,
                       pattern: '^[0-9a-fA-F]{8}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{4}\-[0-9a-fA-F]{12}$'
            end
          end

          response 200 do
            key :description, 'Response is OK'
            schema do
              key :'$ref', :HigherLevelReview
            end
          end

          response 404 do
            key :description, 'ID not found'
            schema do
              key :'$ref', :Errors
            end
          end

          response 502 do
            key :description, 'Bad Gateway: the upstream appeals app returned an invalid response (500+)'
            schema do
              key :'$ref', :Errors
            end
          end
        end
      end

      swagger_path 'v0/appeals/higher_level_review/intake_status/{uuid}' do
        operation :get do
          key :tags, %w[intake_status]
          key :operationId, 'showIntakeStatus'
          key :description, 'After creating a Decision Review, you can use this endpoint to check its _intake status_'\
                            'to see whether or not a Decision Review has been processed in the Caseflow system.'

          parameter do
            key :name, :uuid
            key :in, :path
            key :required, true
            key :description, 'Decision Review UUID'
            schema do
              key :'$ref', :UUID
            end
          end

          response 200 do
            key :description, 'Processing incomplete'
            schema do
              key :'$ref', :IntakeStatus
            end
          end

          response 303 do
            key :description, 'Processing complete; see other'
            schema do
              key :type, :object
              property :meta, type: :object do
                property :Location do
                  key :'$ref', :UUID
                end
              end
            end
          end

          response 404 do
            key :description, 'Decision Review not found'
            schema do
              key :type, :object
              property :errors do
                key :'$ref', :AppealsErrors
              end
            end
          end

          response 500 do
            key :description, 'Unknown error'
            schema do
              key :type, :object
              property :errors do
                key :'$ref', :AppealsErrors
              end
            end
          end
        end
      end
    end
  end
end
