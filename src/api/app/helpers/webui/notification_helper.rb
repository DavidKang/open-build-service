module Webui::NotificationHelper
  MAX_VISIBLE_AVATARS = 6

  def link_to_all
    parameters = params[:type] ? { type: params[:type] } : {}
    if params['show_all'] # already showing all
      link_to('Show less', my_notifications_path(parameters), class: 'btn btn-sm btn-secondary ml-2')
    else
      parameters.merge!({ show_all: 1 })
      link_to('Show all', my_notifications_path(parameters), class: 'btn btn-sm btn-secondary ml-2')
    end
  end

  def filter_notification_link(link_text, amount, filter_item)
    link_to(my_notifications_path(filter_item), class: filter_css(filter_item)) do
      concat(link_text)
      concat(tag.span(amount, class: "badge #{badge_color(filter_item)} align-text-top ml-2")) if amount && amount.positive?
    end
  end

  def notification_icon(notifiable_type)
    return image_tag('request_icon', size: 18, title: 'Request notification') if notifiable_type == 'BsRequest'

    capture do
      tag.i(class: 'fas fa-comments mr-1', title: 'Comment notification')
    end
  end

  def request_state(notification)
    return unless notification.notifiable_type == 'BsRequest'

    state = notification.notifiable.state
    color = request_badge_color(state)

    capture do
      tag.span(state, class: "badge badge-#{color}")
    end
  end

  def request_badge_color(state)
    case state
    when :review, :new
      'secondary'
    when :declined, :revoke
      'danger'
    when :superseded
      'warning'
    when :accepted
      'success'
    else
      'dark'
    end
  end

  def notification_link(notification)
    link_text = case notification.event_type
                # TODO: add 'Event::ReviewWanted' when converted to BsRequest notification
                when 'Event::RequestStatechange', 'Event::RequestCreate'
                  "Request ##{notification.notifiable.number}"
                when 'Event::CommentForRequest'
                  "Request ##{notification.notifiable.commentable.number}"
                when 'Event::CommentForProject'
                  notification.notifiable.commentable.name
                when 'Event::CommentForPackage'
                  commentable = notification.notifiable.commentable
                  "#{commentable.project.name} / #{commentable.name}"
                end

    link_to(link_text, notification.link_to_notification_target, class: 'mx-1 text-word-break-all')
  end

  def read_unread_link(notification)
    title, icon = notification.unread? ? ['Mark as "Read"', 'fa-check'] : ['Mark as "Unread"', 'fa-undo']

    link_to(my_notification_path(id: notification),
            method: :put, class: 'btn btn-sm btn-outline-success px-3', title: title) do
      concat(tag.i(class: "fas #{icon}"))
    end
  end

  # A limited number of avatars are going to be displayed
  def request_tags(request)
    tags = []

    # Request's reviewers
    if request.state == :review
      open_reviews = request.reviews.where(state: :new)
      open_reviews.limit(MAX_VISIBLE_AVATARS).each do |review|
        tags << reviewers_tags(review)
      end
    end

    if tags.size < MAX_VISIBLE_AVATARS
      # Request's creator
      tags << user_avatar(User.find_by(login: request.creator))
    else
      # Counter
      hidden = (1 + open_reviews.size - MAX_VISIBLE_AVATARS)
      tags << tag.span("+#{hidden}", class: 'rounded-circle bg-light border border-gray-400 avatars-counter',
                                     title: "#{hidden} more users involved")
    end
    tags.reverse
  end

  def user_avatar(user)
    image_tag_for(user, size: 23, custom_class: 'rounded-circle bg-light border border-gray-400')
  end

  def simulated_avatar(icon_color, title)
    tag.span(class: "fa #{icon_color} rounded-circle bg-light border border-gray-400 simulated-avatar", title: title)
  end

  private

  def filter_css(filter_item)
    css_class = 'list-group-item list-group-item-action'
    css_class += ' active' if notification_filter_active?(filter_item)
    css_class
  end

  def notification_filter_active?(filter_item)
    if params[:project].present?
      filter_item[:project] == params[:project]
    elsif params[:type].present?
      filter_item[:type] == params[:type]
    else
      filter_item[:type] == 'unread'
    end
  end

  def badge_color(filter_item)
    notification_filter_active?(filter_item) ? 'badge-light' : 'badge-primary'
  end

  def reviewers_tags(review)
    return user_avatar(User.find_by(login: review.by_user)) if review.by_user
    return user_avatar(Group.find_by(title: review.by_group)) if review.by_group
    return simulated_avatar('fa-archive text-warning', "Package #{review.by_project}/#{review.by_package}") if review.by_package
    return simulated_avatar('fa-cubes text-secondary', "Project #{review.by_project}") if review.by_project
  end
end
