RSpec.shared_examples 'a subscriptions form for subscriber' do
  it 'updates the source_maintainer subscription to channel = disabled' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(user)
                                    .find_by(receiver_role: 'source_maintainer', channel: :disabled)
    expect(subscription.channel).to eq('disabled')
  end

  it 'updates the target_maintainer subscription to channel = disabled' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(user)
                                    .find_by(receiver_role: 'target_maintainer', channel: :disabled)
    expect(subscription.channel).to eq('disabled')
  end

  it 'creates the creator subscription with channel = instant_email' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(user)
                                    .find_by(receiver_role: 'creator', channel: :instant_email)
    expect(subscription.channel).to eq('instant_email')
  end

  it 'creates the reviewer subscription with channel = instant_email' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(user)
                                    .find_by(receiver_role: 'reviewer', channel: :instant_email)
    expect(subscription.channel).to eq('instant_email')
  end

  it 'creates the reviewer subscription with channel = web' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(user)
                                    .find_by(receiver_role: 'reviewer', channel: :web)
    expect(subscription.channel).to eq('web')
  end

  it 'creates the creator subscription with channel = rss' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(user)
                                    .find_by(receiver_role: 'creator', channel: :rss)
    expect(subscription.channel).to eq('rss')
  end
end

RSpec.shared_examples 'a subscriptions form for default' do
  it 'updates the source_maintainer subscription to channel = disabled' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(nil)
                                    .find_by(receiver_role: 'source_maintainer', channel: :disabled)
    expect(subscription.channel).to eq('disabled')
  end

  it 'updates the target_maintainer subscription to channel = disabled' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(nil)
                                    .find_by(receiver_role: 'target_maintainer', channel: :disabled)
    expect(subscription.channel).to eq('disabled')
  end

  it 'creates the creator subscription with channel = instant_email' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(nil)
                                    .find_by(receiver_role: 'creator', channel: :instant_email)
    expect(subscription.channel).to eq('instant_email')
  end

  it 'creates the reviewer subscription with channel = instant_email' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(nil)
                                    .find_by(receiver_role: 'reviewer', channel: :instant_email)
    expect(subscription.channel).to eq('instant_email')
  end

  it 'creates the creator subscription with channel = web' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(nil)
                                    .find_by(receiver_role: 'reviewer', channel: :web)
    expect(subscription.channel).to eq('web')
  end

  it 'creates the reviewer subscription with channel = rss' do
    subscription = EventSubscription.for_eventtype('Event::RequestStatechange')
                                    .for_subscriber(nil)
                                    .find_by(receiver_role: 'creator', channel: :rss)
    expect(subscription.channel).to eq('rss')
  end
end
