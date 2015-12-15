require 'spec_helper'
describe 'role_logging' do

  context 'with defaults for all parameters' do
    it { should contain_class('role_logging') }
  end
end
