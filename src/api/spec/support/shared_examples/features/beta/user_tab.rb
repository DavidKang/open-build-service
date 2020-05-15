RSpec.shared_examples 'user tab' do
  let(:user_tab_user) { create(:confirmed_user, :with_home, login: 'user_tab_user') }
  let!(:other_user) { create(:confirmed_user, :with_home, login: 'other_user') }
  let(:reader) { create(:confirmed_user, login: 'reader_user') }
  # default to prevent "undefined local variable or method `package'" error
  let!(:package) { nil }
  let!(:project) { nil }

  def toggle_checkbox(html_id)
    # Workaround: Bootstrap's custom-control causes the checkbox's input field to be at
    # a different location than it visually appears. For browsers this is not an issue, but
    # capybara throws an error because "is not clickable at point (596, 335). Other element
    # would receive the click".
    # Thus we have to remove bootstraps custom-control classes.
    page.execute_script("$('##{html_id}').removeClass('custom-control-input')")
    page.execute_script("$('label[for=#{html_id}]').removeClass('custom-control-label')")
    scroll_page(html_id) if mobile?
    find_field(html_id).click
    # FIXME: Needed to wait for the Ajax call to perform
    sleep(1)
  end

  def uncollapse_datatable_row(html_id, text)
    # Workaround: When Capybara clicks on a td element with a plus sign ('+') to uncollapse a row,
    # this element gets changed to a minus sign ('-'), Capybara marks it as obsolete, and then
    # clicks the link next to the sign, going to an undesidered page.
    # To avoid this behaviour, the href attribute of the link is removed, so Capybara can not click
    # in the link.
    page.execute_script("$('##{html_id}').parents('td').prev().find('a').removeAttr('href')")
    find('td', text: "#{text}").click
    scroll_page(html_id)
  end

  def scroll_page(html_id)
    # Workaround: To click on elements for mobile, we need first to scroll
    # the page to make the element visible in the viewport.
    navbar_height = 80
    page.execute_script("window.scrollTo(0, $('##{html_id}').offset().top - #{navbar_height})")
  end

  describe 'user roles' do
    let!(:bugowner_user_role) do
      create(:relationship,
             project: project,
             package: package,
             user: user_tab_user,
             role: Role.find_by_title('bugowner'))
    end
    let!(:reader_user_role) do
      create(:relationship,
             project: project,
             package: package,
             user: reader,
             role: Role.find_by_title('reader'))
    end

    before do
      login user_tab_user
      visit project_path
      click_link('Users')
    end

    scenario 'Viewing user roles' do
      expect(page).to have_text('User Roles')
      expect(find_field('user_maintainer_user_tab_user', visible: false)).to be_checked
      expect(find_field('user_bugowner_user_tab_user', visible: false)).to be_checked
      expect(find_field('user_reviewer_user_tab_user', visible: false)).not_to be_checked
      expect(find_field('user_downloader_user_tab_user', visible: false)).not_to be_checked
      expect(find_field('user_reader_user_tab_user', visible: false)).not_to be_checked

      uncollapse_datatable_row('user_maintainer_user_tab_user', user_tab_user) if mobile?
      expect(page).to have_selector("a.remove-user[data-object='user_tab_user']")
    end

    scenario 'Add non existent user' do
      click_menu_link('Actions', 'Add User')
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara

      within('#add-user-role-modal') do
        fill_in('User:', with: 'Jimmy')
        click_button('Accept')
      end

      expect(page).to have_text("Couldn't find User with login = Jimmy")
    end

    scenario 'Add an existing user' do
      click_menu_link('Actions', 'Add User')
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara

      within('#add-user-role-modal') do
        fill_in('User:', with: other_user.login)
        click_button('Accept')
      end

      expect(page).to have_text("Added user #{other_user.login} with role maintainer")
      expect(page).to have_text(other_user.realname)
      within('#user-table') do
        # package / project owner plus other user and reader
        expect(find_all('tbody tr').count).to eq(3)
      end

      # Adding a user twice...
      click_menu_link('Actions', 'Add User')
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara

      within('#add-user-role-modal') do
        fill_in('User:', with: other_user.login)
        click_button('Accept')
      end

      expect(page).to have_text('Relationship already exists')

      click_link('Users')
      within('#user-table') do
        expect(find_all('tbody tr').count).to eq(3)
      end
    end

    scenario 'Remove user from package / project' do
      if mobile?
        uncollapse_datatable_row('user_maintainer_reader_user', reader)
        # Datatables adds a new tr when the row is uncollapsed. In this case there is
        # only one remove-user element.
        find('.remove-user').click
      else
        find('td', text: "#{reader.realname} (reader_user)").ancestor('tr').find('.remove-user').click
      end
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara
      click_button('Delete')

      expect(page).to have_text('Removed user reader_user')
      expect(page).not_to have_css('a', text: "#{reader.realname} (reader_user)")
    end

    scenario 'Add role to user' do
      toggle_checkbox('user_reviewer_user_tab_user')

      visit project_path # project_users_path
      click_link('Users')
      expect(find_field('user_reviewer_user_tab_user', visible: false)).to be_checked
    end

    scenario 'Remove role from user' do
      toggle_checkbox('user_bugowner_user_tab_user')

      visit project_path
      click_link('Users')
      expect(find_field('user_bugowner_user_tab_user', visible: false)).not_to be_checked
    end
  end

  describe 'group roles' do
    let!(:group) { create(:group, title: 'existing_group') }
    let!(:other_group) { create(:group, title: 'other_group') }
    let!(:maintainer_group_role) { create(:relationship, project: project, package: package, group: group) }
    let!(:bugowner_group_role) do
      create(:relationship,
             project: project,
             package: package,
             group: group,
             role: Role.find_by_title('bugowner'))
    end

    before do
      login user_tab_user
      visit project_path
      click_link('Users')
    end

    scenario 'Viewing group roles' do
      expect(page).to have_text('Group Roles')
      expect(find_field('group_maintainer_existing_group', visible: false)).to be_checked
      expect(find_field('group_bugowner_existing_group', visible: false)).to be_checked
      expect(find_field('group_reviewer_existing_group', visible: false)).not_to be_checked
      expect(find_field('group_downloader_existing_group', visible: false)).not_to be_checked
      expect(find_field('group_reader_existing_group', visible: false)).not_to be_checked

      uncollapse_datatable_row('group_maintainer_existing_group', group) if mobile?
      expect(page).to have_selector("a.remove-group[data-object='existing_group']")
    end

    scenario 'Add non existent group' do
      click_menu_link('Actions', 'Add Group')
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara

      within('#add-group-role-modal') do
        fill_in('Group:', with: 'unknown group')
        click_button('Accept')
      end

      expect(page).to have_text("Couldn't find Group 'unknown group'")
    end

    scenario 'Add an existing group' do
      click_menu_link('Actions', 'Add Group')
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara

      within('#add-group-role-modal') do
        fill_in('Group:', with: other_group.title)
        click_button('Accept')
      end

      expect(page).to have_text("Added group #{other_group.title} with role maintainer")
      within('#group-table') do
        # existing group plus new one
        expect(find_all('tbody tr').count).to eq(2)
      end

      # Adding a group twice...
      click_menu_link('Actions', 'Add Group')
      sleep 1 # FIXME: Needed to avoid a flickering test because the animation of the modal is sometimes faster than capybara

      within('#add-group-role-modal') do
        fill_in('Group:', with: other_group.title)
        click_button('Accept')
      end

      expect(page).to have_text('Relationship already exists')

      click_link('Users')
      within('#group-table') do
        expect(find_all('tbody tr').count).to eq(2)
      end
    end

    scenario 'Add role to group' do
      toggle_checkbox('group_reviewer_existing_group')

      visit project_path
      click_link('Users')
      expect(find('#group_reviewer_existing_group', visible: false)).to be_checked
    end

    scenario 'Remove role from group' do
      toggle_checkbox('group_bugowner_existing_group')

      visit project_path
      click_link('Users')
      expect(find_field('group_bugowner_existing_group', visible: false)).not_to be_checked
    end
  end
end
