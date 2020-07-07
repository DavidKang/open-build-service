class Webui::Users::NotificationsController < Webui::WebuiController
  MAX_PER_PAGE = 300
  VALID_NOTIFICATION_TYPES = ['read', 'comments', 'requests', 'unread'].freeze

  before_action :require_login
  before_action :check_param_type, :check_param_project, only: :index

  def index
    @notifications = fetch_notifications
    @projects_for_filter = projects_for_filter
    @notifications_count = notifications_count
  end

  def update
    notification = User.session.notifications.find(params[:id])
    authorize notification, policy_class: NotificationPolicy

    if notification.toggle(:delivered).save
      flash[:success] = "Successfully marked the notification as #{notification.unread? ? 'unread' : 'read'}"
    else
      flash[:error] = "Couldn't mark the notification as #{notification.unread? ? 'read' : 'unread'}"
    end

    respond_to do |format|
      format.js do
        render partial: 'update', locals: {
          notifications: fetch_notifications,
          projects_for_filter: projects_for_filter,
          notifications_count: notifications_count
        }
      end
    end
  end

  private

  def check_param_type
    return if params[:type].nil? || VALID_NOTIFICATION_TYPES.include?(params[:type])

    flash[:error] = 'Filter not valid.'
    redirect_to my_notifications_path
  end

  def check_param_project
    return unless params[:project] == ''

    flash[:error] = 'Filter not valid.'
    redirect_to my_notifications_path
  end

  def show_all
    total = @notifications.size
    if total > MAX_PER_PAGE
      flash.now[:info] = "You have too many notifications. Displaying a maximum of #{MAX_PER_PAGE} notifications per page."
    end
    @notifications = @notifications.page(params[:page]).per([total, MAX_PER_PAGE].min)
  end

  # Returns a hash where the key is the name of the project and the value is the amount of notifications
  # associated to that project. The hash is sorted by amount and then name.
  #
  # TODO: drop 'without_reviews' as soon as reviews' notifications disappear.
  def projects_for_filter
    Project.joins(:notifications)
           .where.not(notifications: { notifiable_type: 'Review' })
           .where(notifications: { subscriber: User.session, delivered: false, web: true })
           .order('name desc').group(:name).count # this query returns a sorted-by-name hash like { "home:b" => 1, "home:a" => 3  }
           .sort_by(&:last).reverse.to_h # this sorts the hash by amount: { "home:a" => 3, "home:b" => 1 }
  end

  def notifications_count
    # TODO: drop 'without_reviews' as soon as reviews' notifications disappear.
    counted_notifications = NotificationsFinder.new(User.session.notifications.without_reviews.for_web).unread.group(:notifiable_type).count
    counted_notifications.merge!('unread' => User.session.unread_notifications)
  end

  def fetch_notifications
    # TODO: drop 'without_reviews' as soon as reviews' notifications disappear.
    notifications_for_subscribed_user = User.session.notifications.without_reviews.for_web
    notifications = if params[:project]
                      NotificationsFinder.new(notifications_for_subscribed_user).for_project_name(params[:project])
                    else
                      NotificationsFinder.new(notifications_for_subscribed_user).for_notifiable_type(params[:type])
                    end
    params['show_all'] ? show_all : notifications.page(params[:page])
  end
end
