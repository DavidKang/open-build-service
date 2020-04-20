class GenerateWebNotifications < ActiveRecord::Migration[6.0]
  def up
    Notification::RssFeedItem.all.each do |rss_notification|
      duplicate = rss_notification.dup
      duplicate.type = 'Notification::WebItem'
      # to avoid duplicated web notifications
      Notification::WebItem.find_or_create_by(duplicate.attributes.except('id'))
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
