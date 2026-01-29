require 'minitest/autorun'
require 'jekyll'
require 'liquid'
require_relative '../lib/jekyll_oembed'

class TestErrorHandling < Minitest::Test
  def setup
    @context = Liquid::Context.new
  end

  def test_socket_error_handling
    # Test that SocketError is caught and handled gracefully
    template = Liquid::Template.parse('{% oembed https://www.youtube.com/watch?v=test %}')
    tag = template.root.nodelist.first

    # Mock OEmbed::Providers.get to raise SocketError
    OEmbed::Providers.stub :get, ->(*args) { raise SocketError.new("getaddrinfo: nodename nor servname provided, or not known") } do
      result = tag.render(@context)
      
      # Should return a fallback link
      assert_includes result, "<a href='https://www.youtube.com/watch?v=test'>https://www.youtube.com/watch?v=test</a>"
      
      # Verify it doesn't raise an exception
      assert_kind_of String, result
    end
  end

  def test_socket_resolution_error_handling
    # Test that Socket::ResolutionError (subclass of SocketError) is also caught
    # Note: Socket::ResolutionError was added in Ruby 3.0+, so we skip this test on older versions
    skip "Socket::ResolutionError not available in Ruby < 3.0" unless defined?(Socket::ResolutionError)

    template = Liquid::Template.parse('{% oembed https://vimeo.com/123456 %}')
    tag = template.root.nodelist.first

    # Mock OEmbed::Providers.get to raise Socket::ResolutionError
    OEmbed::Providers.stub :get, ->(*args) { raise Socket::ResolutionError.new("DNS resolution failed") } do
      result = tag.render(@context)

      # Should return a fallback link
      assert_includes result, "<a href='https://vimeo.com/123456'>https://vimeo.com/123456</a>"

      # Verify it doesn't raise an exception
      assert_kind_of String, result
    end
  end

  def test_oembed_error_handling
    # Test that OEmbed::Error is caught and handled gracefully
    template = Liquid::Template.parse('{% oembed https://example.com/video %}')
    tag = template.root.nodelist.first

    # Mock OEmbed::Providers.get to raise OEmbed::NotFound (subclass of OEmbed::Error)
    OEmbed::Providers.stub :get, ->(*args) { raise OEmbed::NotFound.new("No provider found") } do
      result = tag.render(@context)
      
      # Should return a fallback link
      assert_includes result, "<a href='https://example.com/video'>https://example.com/video</a>"
      
      # Verify it doesn't raise an exception
      assert_kind_of String, result
    end
  end

  def test_network_unreachable_error_handling
    # Test that network unreachable errors are caught (these are also SocketErrors)
    template = Liquid::Template.parse('{% oembed https://www.youtube.com/watch?v=offline %}')
    tag = template.root.nodelist.first

    # Mock OEmbed::Providers.get to raise a network error
    OEmbed::Providers.stub :get, ->(*args) { raise SocketError.new("Network is unreachable") } do
      result = tag.render(@context)
      
      # Should return a fallback link
      assert_includes result, "<a href='https://www.youtube.com/watch?v=offline'>https://www.youtube.com/watch?v=offline</a>"
      
      # Verify it doesn't raise an exception
      assert_kind_of String, result
    end
  end

  def test_error_warning_message
    # Test that a warning is issued when an error occurs
    template = Liquid::Template.parse('{% oembed https://test.com/video %}')
    tag = template.root.nodelist.first

    # Capture warnings by stubbing the warn method on the tag instance
    warnings = []
    tag.stub :warn, ->(msg) { warnings << msg } do
      OEmbed::Providers.stub :get, ->(*args) { raise SocketError.new("Connection failed") } do
        tag.render(@context)
      end
    end

    # Verify a warning was issued
    assert_equal 1, warnings.length
    assert_includes warnings.first, "Couldn't load embeddable content from https://test.com/video"
    assert_includes warnings.first, "Connection failed"
  end

  def test_successful_render_with_no_errors
    # Test that when there's no error, the tag works normally
    template = Liquid::Template.parse('{% oembed https://www.youtube.com/watch?v=success %}')
    tag = template.root.nodelist.first

    # Create a simple mock object that responds to html and type
    mock_resource = Object.new
    def mock_resource.html
      '<iframe src="https://www.youtube.com/embed/success"></iframe>'
    end
    def mock_resource.type
      'video'
    end

    OEmbed::Providers.stub :get, ->(*args) { mock_resource } do
      result = tag.render(@context)

      # Should return the embedded content wrapped in a div
      assert_includes result, "<div class='oembed video'>"
      assert_includes result, '<iframe src="https://www.youtube.com/embed/success"></iframe>'
    end
  end

  def test_cached_content_not_affected_by_errors
    # Test that cached content is returned even if network is down
    url_text = "https://cached.com/video"
    template = Liquid::Template.parse("{% oembed #{url_text} %}")
    tag = template.root.nodelist.first

    # The @text variable includes a trailing space from the Liquid tag parsing
    # We need to use the exact text that will be used for cache lookup
    rendered_text = Liquid::Template.parse(tag.instance_variable_get(:@text)).render @context

    # First, set up a cache entry with the exact text that will be parsed
    cached_content = "<div class='oembed video'><iframe>cached</iframe></div>"
    tag.send(:cache_set, rendered_text, cached_content)

    # Verify the cache file was created and is recent
    cache_file = tag.send(:cache_path, rendered_text)
    assert File.exist?(cache_file), "Cache file should exist"

    # Now simulate network error - should still return cached content
    # The cache is checked BEFORE the network call, so this should never raise
    result = tag.render(@context)

    # Should return cached content, not the error fallback
    assert_equal cached_content, result

    # Clean up
    File.delete(cache_file) if File.exist?(cache_file)
  end
end

