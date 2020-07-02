# name: replyto-individual plugin
# about: A plugin that allows exposure of the sender's email address for functionality
#        similar to GNU/Mailman's Reply_Goes_To_List = Poster
# version: 0.0.2
# authors: Alan Schmitz <aschmitz@iastate.edu>, Tarek Loubani <tarek@tarek.org>
# license: aGPLv3
# url: https://github.com/alankeny/discourse-replyto-individual

PLUGIN_NAME ||= "replyto-individual".freeze

enabled_site_setting :replyto_individual_enabled

after_initialize do
  Email::MessageBuilder.class_eval do
    attr_reader :template_args

    ALLOW_REPLY_BY_EMAIL_HEADER = 'X-Discourse-Allow-Reply-By-Email'.freeze

    def header_args
      result = {}
      if @opts[:add_unsubscribe_link]
        unsubscribe_url = @template_args[:unsubscribe_url].presence || @template_args[:user_preferences_url]
        result['List-Unsubscribe'] = "<#{unsubscribe_url}>"
      end

      result['X-Discourse-Post-Id']  = @opts[:post_id].to_s  if @opts[:post_id]
      result['X-Discourse-Topic-Id'] = @opts[:topic_id].to_s if @opts[:topic_id]

      # please, don't send us automatic responses...
      result['X-Auto-Response-Suppress'] = 'All'

      if allow_reply_by_email?
        result[ALLOW_REPLY_BY_EMAIL_HEADER] = true
        result['Reply-To'] = reply_by_email_address
      else
        result['Reply-To'] = from_value
      end

      if SiteSetting.replyto_individual_enabled?
        p = Post.find_by_id @opts[:post_id]
        if p
          result['Reply-To'] = "#{p.user.name} <#{p.user.email}>"
          if SiteSetting.replyto_individual_cc?
            result['CC'] = reply_by_email_address
          end
        else
          return super
        end
      end

      result.merge(Email::MessageBuilder.custom_headers(SiteSetting.email_custom_headers))
    end
  end

  # Fix the Email::Sender method to also insert the reply_key into CC

  Email::Sender.class_eval do
    def set_reply_key(post_id, user_id)
      return unless user_id &&
        post_id &&
        header_value(Email::MessageBuilder::ALLOW_REPLY_BY_EMAIL_HEADER).present?

      # use safe variant here cause we tend to see concurrency issue
      reply_key = PostReplyKey.find_or_create_by_safe!(
        post_id: post_id,
        user_id: user_id
      ).reply_key

      if header_value('Reply-To') =~ /reply_key/i
        @message.header['Reply-To'] =
          header_value('Reply-To').gsub!("%{reply_key}", reply_key)
      end
      if !header_value('CC').blank?
        @message.header['CC'] =
          header_value('CC').gsub!("%{reply_key}", reply_key)
      end
    end
  end
end
