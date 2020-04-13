class NotificationCreator
  EVENTS_TO_NOTIFY = ['Event::RequestStatechange',
                      'Event::RequestCreate',
                      'Event::ReviewWanted',
                      'Event::CommentForProject',
                      'Event::CommentForPackage',
                      'Event::CommentForRequest'].freeze

  NOTIFICATION_SUBCLASS = { all: 'Notification::RssFeedItem',
                            rss: 'Notification::RssFeedItem',
                            web: 'Notification::WebItem' }.freeze

  def initialize(event, notification_type = :all)
    @event = event
    @notification_type = notification_type
  end

  def call
    return unless @event.eventtype.in?(EVENTS_TO_NOTIFY)
    @event.subscriptions(find_by_channel).each do |subscription|
      create_notification_per_subscription(subscription, NOTIFICATION_SUBCLASS[@notification_type])
    end
  rescue StandardError => e
    Airbrake.notify(e, event_id: @event.id)
  end

  private

  def create_notification_per_subscription(subscription, notification_subtype)
    return if subscription.subscriber && subscription.subscriber.away?
    params = subscription.parameters_for_notification.merge!(@event.parameters_for_notification)
    notification_subtype.constantize.find_or_create_by!(params) # avoid duplication
  end

  def find_by_channel
    return if @notification_type == :all
    @notification_type
  end
end
