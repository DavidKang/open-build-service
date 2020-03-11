class Notification < ApplicationRecord
  belongs_to :subscriber, polymorphic: true
  belongs_to :notifiable, polymorphic: true
  belongs_to :comment, foreign_key: 'notifiable_id', class_name: 'Comment'
  belongs_to :bs_request, foreign_key: 'notifiable_id', class_name: 'BsRequest'

  serialize :event_payload, JSON

  scope :stale, -> { where('created_at < ?', 3.months.ago) }
  def comment
    return unless notifiable_type == 'Comment'
    super
  end

  def bs_request
    return unless notifiable_type == 'BsRequest'
    super
  end

  def event
    @event ||= event_type.constantize.new(event_payload)
  end

  def self.cleanup
    Notification.stale.delete_all
  end

  def user_active?
    !subscriber.away?
  end

  def any_user_in_group_active?
    !subscriber.users.recently_seen.empty?
  end
end
