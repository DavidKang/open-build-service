class NotificationPresenter < SimpleDelegator
  def initialize(model)
    @model = model
    super(@model)
  end

  def link_to_notification_target
    case @model.event_type
    when 'Event::RequestStatechange', 'Event::RequestCreate'
      Rails.application.routes.url_helpers.request_show_path(@model.notifiable.number)
    when 'Event::ReviewWanted'
      Rails.application.routes.url_helpers.request_show_path(@model.notifiable.bs_request.number)
    when 'Event::CommentForRequest'
      Rails.application.routes.url_helpers.request_show_path(@model.notifiable.commentable.number, anchor: 'comments-list')
    when 'Event::CommentForProject'
      Rails.application.routes.url_helpers.project_show_path(@model.notifiable.commentable, anchor: 'comments-list')
    when 'Event::CommentForPackage'
      Rails.application.routes.url_helpers.package_show_path(package: @model.notifiable.commentable,
                                                             project: @model.notifiable.commentable.project,
                                                             anchor: 'comments-list')
    else
      ''
    end
  end

  def excerpt
    text =  case @model.notifiable_type
            when 'BsRequest'
              @model.notifiable.description
            when 'Review'
              @model.notifiable.reason
            when 'Comment'
              @model.notifiable.body
            else
              ''
            end
    text.to_s.truncate(100)
  end

  def kind_of_request
    BsRequest.actions_summary(@model.event_payload) if @model.notifiable_type == 'BsRequest'
  end
end
