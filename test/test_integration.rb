require 'minitest/autorun'
require 'jekyll'
require 'liquid'
require_relative '../lib/jekyll_oembed'

class TestIntegration < Minitest::Test
  def test_liquid_template_registration
    # Test that the oembed tag is properly registered with Liquid
    template = Liquid::Template.parse('{% oembed invalid_url %}')
    assert_instance_of Jekyll::OEmbedTag, template.root.nodelist.first
  end

  def test_basic_rendering
    # Test basic rendering functionality
    template = Liquid::Template.parse('{% oembed invalid_url %}')
    context = Liquid::Context.new

    result = template.render(context)
    assert_includes result, "<a href='invalid_url'>invalid_url</a>"
  end

  def test_parameter_handling
    # Test that parameters are properly handled
    template = Liquid::Template.parse('{% oembed https://example.com width=500 %}')
    tag = template.root.nodelist.first

    # Verify the tag was created with the correct text (trim whitespace)
    assert_equal 'https://example.com width=500', tag.instance_variable_get(:@text).strip
  end

  def test_cache_directory_setup
    template = Liquid::Template.parse('{% oembed https://example.com %}')
    tag = template.root.nodelist.first

    # Verify cache directory is set
    assert_equal '/tmp', tag.instance_variable_get(:@cache_dir)
  end
end
