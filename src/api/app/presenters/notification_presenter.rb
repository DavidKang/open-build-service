class NotificationPresenter < SimpleDelegator

  def initialize(model)
    @model = model
    super(@model)
  end

  def link_to_notification_target
    case @model.event_type
    when 'Event::RequestStateChange', 'Event::ReviewWanted', 'Event::RequestCreate'
      Rails.application.routes.url_helpers.request_show_path(@model.bs_request.number)
    when 'Event::CommentForRequest'
      Rails.application.routes.url_helpers.request_show_path(@model.comment.commentable.number)
    when 'Event::CommentForProject'
      Rails.application.routes.url_helpers.project_show_path(@model.comment.commentable)
    when 'Event::CommentForPackage'
      Rails.application.routes.url_helpers.package_show_path(package: @model.comment.commentable, project: @model.comment.commentable.project )
    else
      ''
    end
  end

  def notification_batch
    case @model.event_type
    when 'Event::RequestStateChange', 'Event::RequestCreate'
      'Request'
    when 'Event::ReviewWanted'
      'Review'
    when 'Event::CommentForRequest', 'Event::CommentForProject', 'Event::CommentForPackage'
      'Comment'
    end
  end
end
