class SendEventEmailsJob < ApplicationJob
  queue_as :mailers

  def perform
    Event::Base.where(mails_sent: false).order(created_at: :asc).limit(1000).each do |event|
      email_subscribers = event.subscribers_for_channel(:instant_email)
      event.update_attributes(mails_sent: true) if email_subscribers.empty?

      NotificationCreator.new(event, :web).call
      NotificationCreator.new(event, :rss).call
      send_email(email_subscribers, event)
    end
    true
  end

  private

  def send_email(subscribers, event)
    return if subscribers.empty?
    EventMailer.event(subscribers, event).deliver_now
  rescue StandardError => e
    Airbrake.notify(e, event_id: event.id)
  ensure
    event.update_attributes(mails_sent: true)
  end
end
