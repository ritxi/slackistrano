# Slackistrano

[![Gem Version](https://badge.fury.io/rb/slackistrano.png)](http://badge.fury.io/rb/slackistrano)
[![Code Climate](https://codeclimate.com/github/phallstrom/slackistrano.png)](https://codeclimate.com/github/phallstrom/slackistrano)
[![Build Status](https://travis-ci.org/phallstrom/slackistrano.png?branch=master)](https://travis-ci.org/phallstrom/slackistrano)

Send notifications to [Slack](https://slack.com) about [Capistrano](http://www.capistranorb.com) deployments.

## Requirements

- Capistrano >= 3.8.1
- Ruby >= 2.0
- A Slack account

## Installation

1. Add this line to your application's Gemfile:

   ```ruby
   gem 'slackistrano', github: 'ritxi:slackistrano'
   ```

2. Execute:

   ```
   $ bundle
   ```

3. Require the library in your application's Capfile:

   ```ruby
   require 'slackistrano/capistrano'
   ```

## Configuration

You have two options to notify a channel in Slack when you deploy:

1. Using *Incoming WebHooks* integration, offering more options but requires
   one of the five free integrations. This option provides more messaging
   flexibility.
2. Using *Slackbot*, which will not use one of the five free integrations.

### Incoming Webhook

1. Configure your Slack's Incoming Webhook.
2. Add the following to `config/deploy.rb`:

   ```ruby
   set :slackistrano, {
     webhook: 'your-incoming-webhook-url'
   }
   ```

### Optional Configuration & Overrides

By default Slackistrano will use a default icon and username. These, can be
overriden if you are using the default messaging class (ie. have not specified
your own).

1. Configure per instructions above.
2. Add the following to `config/deploy.rb`:

   ```ruby
   set :slackistrano, {
    ...
    username: 'Foobar the Deployer',
    ...
   }
   ```


### Test your Configuration

Test your setup by running the following command. This will post each stage's
message to Slack in turn.

```
$ cap production slack:deploy:test
```

## Usage

Deploy your application like normal and you should see messages in the channel
you specified.

## Customizing the Messaging

You can customize the messaging posted to Slack by providing your own messaging
class and overriding several methods. Here is one example:

```ruby
if defined?(Slackistrano::Messaging)
   module Slackistrano
     class CustomMessaging < Messaging::Base

       # Suppress starting message.
       def payload_for_starting
         nil
       end

       # Suppress updating message.
       def payload_for_updating
         nil
       end

       # Suppress reverting message.
       def payload_for_reverting
         nil
       end

       def logo
         @logo ||= 'https://url-to-my-logo.jpg'
       end

       # Reference
       # https://docs.microsoft.com/en-us/outlook/actionable-messages/message-card-reference
       def base_message(message, facts = [])
         { '@type' => 'MessageCard',
           '@context' => 'http://schema.org/extensions',
           'themeColor' => '0076D7', 'summary' => message,
           'sections' => [{
             'activityTitle' => "![MyLogo](#{logo}) My App deployment",
             'activitySubtitle' => message,
             'activityImage' => logo,
             'facts' => facts,
             'markdown' => true
           }] }
       end

       # Suppress updating message.
       def payload_for_updating
         base_message("#{deployer} has started deploying branch #{branch} of "\
                      "#{application} to #{stage}")
       end

       # Fancy updated message.
       # See https://api.slack.com/docs/message-attachments
       def payload_for_updated
         revision = fetch(:current_revision)
         base_message('MyApp has been deployed successfully ',
                      [{ name: 'Project',
                         value: '[My Company](https://my-company-url.com)' },
                       { name: 'Environment', value: stage },
                       { name: 'Deployer', value: deployer },
                       { name: 'Revision',
                         value: "[#{revision[0..6]}](https://repository-url/commits/#{revision})" }])
       end

       # Override the deployer helper to pull the best name available (git, password file, env vars).
       # See https://github.com/phallstrom/slackistrano/blob/master/lib/slackistrano/messaging/helpers.rb
       def deployer
         name = `git config user.name`.strip
         name = nil if name.empty?
         name ||= Etc.getpwnam(ENV['USER']).gecos || ENV['USER'] || ENV['USERNAME']
         name
       end
     end
   end
end
```

To set this up:

1. Add the above class to your app, for example `lib/custom_messaging.rb`.

2. Require the library after the requiring of Slackistrano in your application's Capfile.

   ```ruby
   require_relative 'lib/custom_messaging'
   ```

3. Update the `slackistrano` configuration in `config/deploy.rb` and add the `klass` option.

   ```ruby
   set :slackistrano, {
     klass: Slackistrano::CustomMessaging,
     webhook: 'your-incoming-webhook-url'
   }
   ```

4. If you come up with something that you think others would enjoy submit it as
   an issue along with a screenshot of the output from `cap production
   slack:deploy:test` and I'll add it to the Wiki.

## Disabling posting to Slack

You can disable deployment notifications to a specific stage by setting the `:slackistrano`
configuration variable to `false` instead of actual settings.

```ruby
set :slackistrano, false
```

## TODO

- Notify about incorrect configuration settings.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
