$:.unshift(File.join(File.dirname(__FILE__),'..','lib'))
require "minitest/autorun"
require "mocha/setup"
require "gaudi"

module TestHelpers
  def mock_configuration lines
    File.expects(:exists?).returns(true)
    File.expects(:readlines).returns(lines)
    'system.cfg'
  end
end

class TestLoader < MiniTest::Unit::TestCase
  include TestHelpers
  def test_empty_configuration
    config=mock_configuration([])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert_equal(File.join(File.dirname(__FILE__),config), cfg.config_file)
  end
  def test_syntax_error
    config=mock_configuration(['foo'])
    assert_raises(GaudiConfigurationError) { cfg=Gaudi::Configuration::Loader.new(config) }
  end
  def test_comments
    config=mock_configuration(['','#comment'])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert(cfg.config.empty?, "Configuration should be empty")
  end
  def test_import
    config=mock_configuration(['import import.cfg'])
    File.expects(:exists?).with('d:/GitHub/gaudi/test/import.cfg').returns(true).times(2)
    File.expects(:readlines).with('d:/GitHub/gaudi/test/import.cfg').returns([])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert(cfg.config.empty?, "Configuration should be empty")
  end
  def test_environment
    config=mock_configuration(['setenv GAUDI = brilliant builder'])
    cfg=Gaudi::Configuration::Loader.new(config)
    assert_equal('brilliant builder',ENV['GAUDI'])
  end
end

class TestSystemConfiguration < MiniTest::Unit::TestCase
  include TestHelpers
  def test_empty_configuration
    config=mock_configuration([])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert(cfg.respond_to?(:base_dir), "base_dir should be defined.")
  end

  def test_basic_configuration
    config=mock_configuration(['base_dir=.','out_dir=build/'])
    cfg=Gaudi::Configuration::SystemConfiguration.new(config)
    assert_equal(File.dirname(__FILE__), cfg.base_dir)
    assert_equal(File.join(File.dirname(__FILE__),'build'), cfg.out_dir)
  end
end