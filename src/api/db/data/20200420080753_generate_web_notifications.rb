class GenerateWebNotifications < ActiveRecord::Migration[6.0]
  def up
    Notification.update(rss: true, web: true)
    generate_event_subscripitions
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def generate_event_subscripitions
    event_subscriptions = EventSubscription.where(channel: :instant_email).where.not(user_id: nil)
    event_subscriptions.each do |event_subscription|
      create_subscription_for_channel(event_subscription, :rss)
      create_subscription_for_channel(event_subscription, :web)
    end
  end

  def create_subscription_for_channel(event_subscription, channel)
    subscription = EventSubscription.find_by(user_id: event_subscription.user_id,
                                             receiver_role: event_subscription.receiver_role,
                                             eventtype: event_subscription.eventtype,
                                             channel: channel)
    return if subscription

    subscription = EventSubscription.find_or_initialize_by(user_id: event_subscription.user_id,
                                                           receiver_role: event_subscription.receiver_role,
                                                           eventtype: event_subscription.eventtype,
                                                           channel: :disabled)
    subscription.channel = channel
    subscription.save!
  end
end
