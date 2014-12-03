class PRXAccountWhitelist < ActiveRecord::Base

  def self.allow?(account_id)
    !!exists?(prx_account_id: account_id)
  end
end
