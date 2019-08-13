require_relative 'messaging/base'
require 'net/http'
require 'json'
require 'forwardable'

load File.expand_path("../tasks/slack.rake", __FILE__)

module Slackistrano
  class Capistrano

    attr_reader :backend
    private :backend

    extend Forwardable
    def_delegators :env, :fetch, :run_locally

    def initialize(env)
      @env = env
      config = fetch(:slackistrano, {})
      @messaging = if config
                     opts = config.dup.merge(env: @env)
                     klass = opts.delete(:klass) || Messaging::Default
                     klass.new(opts)
                   else
                     Messaging::Null.new
                   end
    end

    def run(action)
      _self = self
      run_locally { _self.process(action, self) }
    end

    def process(action, backend)
      @backend = backend

      payload = @messaging.payload_for(action)
      return if payload.nil?

      payload = {
        username: @messaging.username,
        icon_url: @messaging.icon_url,
      }.merge(payload)

      post(payload)
    end

    private ##################################################

    def post(payload)

      if dry_run?
        post_dry_run(payload)
        return
      end

      begin
        response = post_to_slack(payload)
      rescue => e
        backend.warn("[slackistrano] Error notifying Slack!")
        backend.warn("[slackistrano]   Error: #{e.inspect}")
      end

      if response && response.code !~ /^2/
        warn("[slackistrano] API Failure!")
        warn("[slackistrano]   URI: #{response.uri}")
        warn("[slackistrano]   Code: #{response.code}")
        warn("[slackistrano]   Message: #{response.message}")
        warn("[slackistrano]   Body: #{response.body}") if response.message != response.body && response.body !~ /<html/
      end
    end

    def post_to_slack(payload = {})
      params = payload.to_json
      uri = URI(@messaging.webhook)
      Net::HTTP.post(uri, params, 'Content-Type' => 'application/json')
    end

    def dry_run?
      ::Capistrano::Configuration.env.dry_run?
    end

    def post_dry_run(payload)
        backend.info("[slackistrano] Slackistrano Dry Run:")
      if @messaging.via_slackbot?
        backend.info("[slackistrano]   Team: #{@messaging.team}")
        backend.info("[slackistrano]   Token: #{@messaging.token}")
      else
        backend.info("[slackistrano]   Webhook: #{@messaging.webhook}")
      end
        backend.info("[slackistrano]   Payload: #{payload.to_json}")
    end

  end
end
