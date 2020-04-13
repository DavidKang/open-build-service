class Notification::WebItem < Notification
  scope :for_subscribed_user, lambda { |user|
    where(subscriber_type: 'User', subscriber_id: user)
      .or(where(subscriber_type: 'Group', subscriber_id: user.groups.map(&:id)))
  }
  scope :not_marked_as_done, -> { where(delivered: false) }
end
