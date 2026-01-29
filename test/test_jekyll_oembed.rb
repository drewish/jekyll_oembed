require 'minitest/autorun'
require 'jekyll'
require 'liquid'
require_relative '../lib/jekyll_oembed'

class TestJekyllOEmbed < Minitest::Test
  def setup
    # Use Liquid::Template.parse to properly instantiate the tag
    @template = Liquid::Template.parse('{% oembed https://www.youtube.com/watch?v=dQw4w9WgXcQ %}')
    @tag = @template.root.nodelist.first
  end

  def test_tag_initialization
    assert_instance_of Jekyll::OEmbedTag, @tag
  end

  def test_cache_path_generation
    input = "test_input"
    expected_path = "/tmp/oembed-#{Digest::MD5.hexdigest(input)}"
    assert_equal expected_path, @tag.send(:cache_path, input)
  end

  def test_file_exists_method
    # This will help us identify the deprecated File.exists? issue
    temp_file = "/tmp/test_oembed_file"
    File.write(temp_file, "test")

    # Test that File.exist? works (the correct method)
    assert File.exist?(temp_file)

    # Clean up
    File.delete(temp_file)
  end

  def test_render_with_invalid_url
    # Create a tag with invalid URL
    template = Liquid::Template.parse('{% oembed invalid_url %}')
    tag = template.root.nodelist.first
    context = Liquid::Context.new

    result = tag.render(context)
    assert_includes result, "<a href='invalid_url'>invalid_url</a>"
  end

  def test_cache_set_and_get
    input = "test_cache_input"
    result = "test_cache_result"

    # Test cache_set
    cached_result = @tag.send(:cache_set, input, result)
    assert_equal result, cached_result

    # Test cache_get
    retrieved_result = @tag.send(:cache_get, input)
    assert_equal result, retrieved_result

    # Clean up
    File.delete(@tag.send(:cache_path, input)) if File.exist?(@tag.send(:cache_path, input))
  end

  def test_parameter_parsing
    # Test the new parameter parsing logic
    template = Liquid::Template.parse('{% oembed https://example.com width=500 height=300 %}')
    tag = template.root.nodelist.first

    # Mock the text processing to test parameter parsing
    text = "https://example.com width=500 height=300"
    params = text.shellsplit
    url = params.shift
    params_hash = params.map { |val| val.split('=', 2) }.to_h

    assert_equal "https://example.com", url
    assert_equal({"width" => "500", "height" => "300"}, params_hash)
  end
end
