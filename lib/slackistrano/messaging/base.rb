require 'forwardable'
require_relative 'helpers'

module Slackistrano
  module Messaging
    class Base

      include Helpers

      extend Forwardable
      def_delegators :env, :fetch

      attr_reader :team, :webhook, :options

      def initialize(options = {})
        @options = options.dup

        @env = options.delete(:env)
        @team = options.delete(:team)
        @webhook = options.delete(:webhook)
      end

      def base_message(message, facts = [])
        {
          '@type' => 'MessageCard',
          '@context' => 'http://schema.org/extensions',
          'themeColor' => '0076D7',
          'summary' => message,
          'sections' => [{
            'activityTitle' => 'Deployment',
            'activitySubtitle' => message,
            'facts' => facts,
            'markdown' => true
          }]
        }
      end

      def payload_for_starting
        base_message "#{deployer} has started deploying branch #{branch} of #{application} to #{stage}"
      end

      def payload_for_updating
        base_message "#{deployer} is deploying branch #{branch} of #{application} to #{stage}"
      end

      def payload_for_reverting
        base_message "#{deployer} has started rolling back branch #{branch} of #{application} to #{stage}"
      end

      def payload_for_updated
        base_message "#{deployer} has finished deploying branch #{branch} of #{application} to #{stage}"
      end

      def payload_for_reverted
        base_message "#{deployer} has finished rolling back branch of #{application} to #{stage}"
      end

      def payload_for_failed
        base_message "#{deployer} has failed to #{deploying? ? 'deploy' : 'rollback'} branch #{branch} of #{application} to #{stage}"
      end

      ################################################################################

      def payload_for(action)
        method = "payload_for_#{action}"
        respond_to?(method) && send(method)
      end

      def via_slackbot?
        @webhook.nil?
      end

    end
  end
end

require_relative 'default'
require_relative 'null'
