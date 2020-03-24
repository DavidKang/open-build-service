class SetNotificationNotifiable < ActiveRecord::Migration[5.2]
  def up
    set_notifiable_for_review_wanted
    set_notifiable_for_comment_for_review
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def set_notifiable_for_review_wanted
    notifications = Notification.with_notifiable.where(event_type: 'Event::ReviewWanted', subscriber_type: 'User')
                                .select { | n| n.notifiable.nil? }

    notifications.each do |notification|
      review = Review.find_by(bs_request_id: n.notifiable_id, reviewer: n.subscriber.login)
      notification.notifiable_id = review.try(:id)
      notification.save
    end
  end

  def set_notifiable_for_comment_for_review
    notifications = Notification.with_notifiable.where(event_type: 'Event::CommentForReview', subscriber_type: 'User')
                                .select { | n| n.notifiable.nil? }

    notifications.each do |notification|
      commenter = User.find_by(login: notification.event_payload['commenter'])
      comment = Comment.find_by(commentable_id: notification.notifiable_id,
                                commentable_type: 'BsRequest',
                                body: last.event_payload['comment_body'],
                                user_id: commenter.id )
      notification.notifiable_id = comment.try(:id)
      notification.save
    end
  end
end
