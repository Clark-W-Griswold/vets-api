# frozen_string_literal: true

require 'common/models/redis_store'
require 'common/models/concerns/cache_aside'

# Facade for GI.
class Gi < Common::RedisStore
  include Common::CacheAside

  REDIS_CONFIG_KEY = :gi_response
  redis_config_key REDIS_CONFIG_KEY

  attr_accessor :rest_call, :scrubbed_params

  # Creates a new Gi instance for a controller.
  #
  # @param rest_call [String] the GI::Client method to call
  # @param scrubbed_params [Hash] the params to be used with the rest_call
  # @return [Gi] an instance of this class
  def self.for_controller(rest_call, scrubbed_params)
    gi = Gi.new
    gi.rest_call = rest_call
    gi.scrubbed_params = scrubbed_params
    gi
  end

  # The status of the last GI response
  #
  # @return [String] the status of the last MVI response
  delegate :status, to: :gi_response

  # The body of the last GI response
  #
  # @return
  delegate :body, to: :gi_response

  # @return the response returned from GI Client
  def gi_response
    @gi_response ||= response_from_redis_or_service
  end

  private

  def response_from_redis_or_service
    do_cached_with(key: rest_call.to_s + scrubbed_params.to_s) do
      gi_service.send(rest_call, scrubbed_params)
    end
  end

  def gi_service
    @client ||= ::GI::Client.new
  end

  def save
    saved = super
    expire(record_ttl) if saved
    saved
  end

  def record_ttl
    REDIS_CONFIG[REDIS_CONFIG_KEY.to_s]['each_ttl']
  end
end
