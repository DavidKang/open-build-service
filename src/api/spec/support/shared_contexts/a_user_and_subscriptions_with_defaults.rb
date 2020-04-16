RSpec.shared_context 'a user and subscriptions with defaults' do
  let!(:user) { create(:confirmed_user) }

  let!(:user_subscription1) do
    create(
      :event_subscription,
      eventtype: 'Event::RequestStatechange',
      receiver_role: :source_maintainer,
      user: user,
      channel: 'instant_email'
    )
  end
  let!(:user_subscription2) do
    create(
      :event_subscription,
      eventtype: 'Event::RequestStatechange',
      receiver_role: :target_maintainer,
      user: user,
      channel: 'instant_email'
    )
  end

  let!(:default_subscription1) do
    create(
      :event_subscription,
      eventtype: 'Event::RequestStatechange',
      receiver_role: :source_maintainer,
      user: nil,
      group: nil,
      channel: 'instant_email'
    )
  end
  let!(:default_subscription2) do
    create(
      :event_subscription,
      eventtype: 'Event::RequestStatechange',
      receiver_role: :target_maintainer,
      user: nil,
      group: nil,
      channel: 'instant_email'
    )
  end

  let(:subscription_params) do
    {
      '0' => { channel: 'instant_email', eventtype: 'Event::RequestStatechange', receiver_role: 'source_maintainer' },
      '1' => { channel: 'instant_email', eventtype: 'Event::RequestStatechange', receiver_role: 'target_maintainer' },
      '2' => { enable: 'true', channel: 'instant_email', eventtype: 'Event::RequestStatechange', receiver_role: 'creator' },
      '3' => { enable: 'true', channel: 'instant_email', eventtype: 'Event::RequestStatechange', receiver_role: 'reviewer' },
      '4' => { enable: 'true', channel: 'rss', eventtype: 'Event::RequestStatechange', receiver_role: 'creator' },
      '5' => { enable: 'true', channel: 'web', eventtype: 'Event::RequestStatechange', receiver_role: 'reviewer' }
    }
  end
end
