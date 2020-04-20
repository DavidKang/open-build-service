require 'rails_helper'
require Rails.root.join('db/data/20200420080753_generate_web_notifications.rb')

RSpec.describe GenerateWebNotifications, type: :migration do
  describe 'up' do
    let(:owner) { create(:confirmed_user, login: 'bob') }
    let(:requester) { create(:confirmed_user, login: 'ann') }
    let!(:rss_notifications) { create_list(:rss_notification, 5, subscriber: owner) }
    let!(:event_subscription_1) { create(:event_subscription_comment_for_project, user: owner) }
    let!(:event_subscription_2) { create(:event_subscription_comment_for_project, user: owner, receiver_role: 'maintainer') }
    let!(:event_subscription_3) { create(:event_subscription_comment_for_project, user: owner, receiver_role: 'bugowner') }
    let!(:event_subscription_4) { create(:event_subscription_comment_for_project, user: owner, receiver_role: 'bugowner', channel: :rss) }
    let!(:default_subscription) { create(:event_subscription_comment_for_project_without_subscriber, receiver_role: 'bugowner') }

    subject { GenerateWebNotifications.new.up }

    it { expect { subject }.to change(EventSubscription, :count).from(5).to(10) }
  end
end
