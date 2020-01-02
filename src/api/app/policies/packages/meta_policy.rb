module Packages
  class MetaPolicy < ApplicationPolicy
    def update?
      user.can_modify?(record) && !source_access?
    end

    def source_access?
      record.disabled_for?('sourceaccess', nil, nil)
    end
  end
end