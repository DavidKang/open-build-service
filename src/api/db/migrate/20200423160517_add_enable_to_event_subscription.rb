class AddEnableToEventSubscription < ActiveRecord::Migration[6.0]
  def up
    safety_assured { add_column :event_subscriptions, :enable, :boolean, default: false }
  end

  def down
    safety_assured { remove_column :event_subscriptions, :enable, :boolean }
  end
end
