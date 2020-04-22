class AddEmailRssAndWebToEventSubscription < ActiveRecord::Migration[6.0]
  def change
    add_column :event_subscriptions, :email, :boolean
    add_column :event_subscriptions, :web, :boolean
    add_column :event_subscriptions, :rss, :boolean
  end
end
