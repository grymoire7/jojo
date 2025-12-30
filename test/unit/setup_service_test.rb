require_relative '../test_helper'
require_relative '../../lib/jojo/setup_service'
require 'thor'

describe Jojo::SetupService do
  before do
    @cli = Object.new
  end

  describe '#initialize' do
    it 'stores cli_instance and force flag' do
      service = Jojo::SetupService.new(cli_instance: @cli, force: true)
      _(service.instance_variable_get(:@cli)).must_be_same_as @cli
      _(service.instance_variable_get(:@force)).must_equal true
    end

    it 'defaults force to false' do
      service = Jojo::SetupService.new(cli_instance: @cli)
      _(service.instance_variable_get(:@force)).must_equal false
    end

    it 'initializes tracking arrays' do
      service = Jojo::SetupService.new(cli_instance: @cli)
      _(service.instance_variable_get(:@created_files)).must_equal []
      _(service.instance_variable_get(:@skipped_files)).must_equal []
    end
  end
end
