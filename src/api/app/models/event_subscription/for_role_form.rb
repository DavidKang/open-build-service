class EventSubscription
  class ForRoleForm
    attr_reader :name, :channels, :subscriber

    def initialize(role_name, event, subscriber)
      @subscriber = subscriber
      @name = role_name
      @event = event
      @channels = []
      @subscriptions = []
    end

    def call
      @channels = EventSubscription.channels.keys[1..-1].map do |channel|
        find_subscription_for_event_class_and_role(@event, name, channel)
      end

      self
    end

    private

    def find_subscription_for_event_class_and_role(event_class, role, channel)
      subscriber_subscription =
        find_subscription_for_subscriber(event_class, role, channel) || find_subscription_for_subscriber(event_class, :all, channel)
      default_subscription = find_default_subscription(event_class, role, channel)

      # 1. Pick the subscriber's subscription if it exists
      subscription = if subscriber.present? && subscriber_subscription.present?
                       subscriber_subscription

                     # 2. Pick the default subscription
                     elsif default_subscription.present?
                       default_subscription

                     # 3. Otherwise instantiate a new subscription
                     else
                       EventSubscription.new(
                         subscriber: subscriber,
                         eventtype: event_class.to_s,
                         receiver_role: role,
                         channel: 'disabled'
                       )
                     end

      EventSubscription::ForChannelForm.new(channel, subscription)
    end

    def find_subscription_for_subscriber(event_class, role, channel)
      subscriber_subscriptions.find { |s| s.event_class == event_class && s.receiver_role == role && s.channel == channel }
    end

    def find_default_subscription(event_class, role, channel)
      default_subscriptions.find { |s| s.event_class == event_class && s.receiver_role == role && s.channel == channel }
    end

    def subscriber_subscriptions
      @subscriber_subscriptions ||= EventSubscription.for_subscriber(subscriber)
    end

    def default_subscriptions
      @default_subscriptions ||= EventSubscription.defaults
    end
  end
end
