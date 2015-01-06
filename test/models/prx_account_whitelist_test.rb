require 'test_helper'

describe PRXAccountWhitelist do

  it 'can add prx account ids' do
    pawl = PRXAccountWhitelist.create(prx_account_id: 10000)
    pawl.wont_be_nil
  end


  it 'allows prx account ids' do
    PRXAccountWhitelist.where(prx_account_id: 10001).delete_all
    PRXAccountWhitelist.allow?(10001).must_equal false
    pawl = PRXAccountWhitelist.create!(prx_account_id: 10001)
    PRXAccountWhitelist.allow?(10001).must_equal true
  end

end
