class Webui::Users::NotificationsController < Webui::WebuiController
  before_action :require_login

  def index
    notification_type = params[:type]
    case notification_type
    when 'done'
      @notifications = Notification.where(delivered: true)
                                   .where("(subscriber_type = 'User' AND subscriber_id = ?) OR (subscriber_type = 'Group' AND subscriber_id IN (?))",
                                          User.session, User.session.groups.map(&:id))
    when 'reviews'
      @notifications = []
    when 'comments'
      @notifications = Notification.where(notifiable_type: 'Comment', delivered: false)
                                   .where("(subscriber_type = 'User' AND subscriber_id = ?) OR (subscriber_type = 'Group' AND subscriber_id IN (?))",
                                          User.session, User.session.groups.map(&:id))
    when 'state_changes'
      @notifications = Notification.where(notifiable_type: 'BsRequest', delivered: false).where.not(bs_request_oldstate: nil)
                                   .where("(subscriber_type = 'User' AND subscriber_id = ?) OR (subscriber_type = 'Group' AND subscriber_id IN (?))",
                                          User.session, User.session.groups.map(&:id))
    else
      @notifications = Notification.where(delivered: false)
                                   .where("(subscriber_type = 'User' AND subscriber_id = ?) OR (subscriber_type = 'Group' AND subscriber_id IN (?))",
                                          User.session, User.session.groups.map(&:id))
    end
  end

  def set_done
    notification_ids = params[:notification_ids]
    begin
      Notification.where("(subscriber_type = 'User' AND subscriber_id = ?) OR (subscriber_type = 'Group' AND subscriber_id IN (?))",
                       User.session, User.session.groups.map(&:id)).where(id: notification_ids).update_all(delivered: true)
      flash[:success] = 'The notifications are successfully marked as done'
      redirect_back(fallback_location: root_path)
    rescue
      flash[:error] = "Couldn't mark the selected notifications as done"
      redirect_back(fallback_location: root_path)
    end
  end
end
