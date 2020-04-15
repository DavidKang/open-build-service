class EventSubscription
  class ForChannelForm
    attr_reader :name, :subscription
    delegate :enabled?, to: :subscription

    def initialize(channel_name, subscription)
      @name = channel_name
      @subscription = subscription
    end

    def subscription_params(index)
      @index = index
      "#{subscription_channel_param}&#{subscription_eventtype_param}&#{subscription_receiver_role_param}"
    end

    private

    def subscription_channel_param
      "subscriptions[#{@index}][channel]=#{name}"
    end

    def subscription_eventtype_param
      "subscriptions[#{@index}][eventtype]=#{subscription.eventtype}"
    end

    def subscription_receiver_role_param
      "subscriptions[#{@index}][receiver_role]=#{subscription.receiver_role}"
    end
  end
end
