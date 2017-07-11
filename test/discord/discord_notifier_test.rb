require 'test_helper'
require 'net/http'
require 'json'

class Discord::NotifierTest < Minitest::Test
  def teardown
    Discord::Notifier.setup do |config|
      config.url = nil
      config.username = nil
      config.avatar_url = nil
      config.wait = nil
    end
  end

  def test_configuration
    Discord::Notifier.setup do |config|
      config.url = 'http://test.com'
      config.username = 'Gem Test'
      config.avatar_url = 'http://avatar.com/discord.png'
    end

    expected_config = Discord::Config.new 'http://test.com',
                                          'Gem Test',
                                          'http://avatar.com/discord.png',
                                          nil

    Discord::Notifier.setup do |config|
      assert_equal expected_config, config
    end
  end

  def test_string_message
    expected_payload = {
      url: 'http://test.com',
      username: 'Gem Test',
      avatar_url: 'http://avatar.com/discord.png',
      content: 'String Message'
    }.to_json

    @mock = Minitest::Mock.new
    @mock.expect(:post, true, [JSON.parse(expected_payload)])

    Discord::Notifier.setup do |config|
      config.url = 'http://test.com'
      config.username = 'Gem Test'
      config.avatar_url = 'http://avatar.com/discord.png'
    end

    Net::HTTP.stub :post, ->(uri, params, headers) {
      @mock.post JSON.parse(params)
    } do
      Discord::Notifier.message "String Message"
    end

    @mock.verify
  end

  def test_embed_message
    expected_payload = {
      url: 'http://test.com',
      username: 'Gem Test',
      avatar_url: 'http://avatar.com/discord.png',
      embeds: [{
        title: 'Embed Message Test',
        description: 'Sending an embed through Discord Notifier',
        url: 'http://github.com/ianmitchell/discord_notifier',
        color: 0x008000,
        thumbnail: {
          url: 'http://avatar.com/discord.png'
        },
        author: {
          name: 'Ian Mitchell',
          url: 'http://ianmitchell.io'
        },
        footer: {
          text: 'Mini MiniTest Test'
        },
        fields: [
          {
            name: 'Content',
            value: 'This is a content section'
          },
          {
            name: 'Subsection',
            value: 'This is a content subsection'
          }
        ]
      }]
    }.to_json

    @mock = Minitest::Mock.new
    @mock.expect(:post, true, [JSON.parse(expected_payload)])

    Discord::Notifier.setup do |config|
      config.url = 'http://test.com'
      config.username = 'Gem Test'
      config.avatar_url = 'http://avatar.com/discord.png'
    end

    Net::HTTP.stub :post, ->(uri, params, headers) {
      @mock.post JSON.parse(params)
    } do
      embed = Discord::Embed.new do
        title 'Embed Message Test'
        description 'Sending an embed through Discord Notifier'
        url 'http://github.com/ianmitchell/discord_notifier'
        color 0x008000
        thumbnail url: 'http://avatar.com/discord.png'
        author name: 'Ian Mitchell',
               url: 'http://ianmitchell.io'
        footer text: 'Mini MiniTest Test'
        add_field name: 'Content', value: 'This is a content section'
        add_field name: 'Subsection', value: 'This is a content subsection'
      end

      Discord::Notifier.message embed
    end

    @mock.verify
  end

  def test_custom_config_message
    @custom_config = {
      url: 'http://custom.com',
      username: 'Gem Config Test',
      avatar_url: 'http://avatar.com/slack.png',
      wait: true
    }

    expected_payload = {
      content: 'String Message'
    }.merge(@custom_config).to_json

    @mock = Minitest::Mock.new
    @mock.expect(:post, true, [JSON.parse(expected_payload)])

    Discord::Notifier.setup do |config|
      config.url = 'http://test.com'
      config.username = 'Gem Test'
      config.avatar_url = 'http://avatar.com/discord.png'
      config.wait = true
    end

    Net::HTTP.stub :post, ->(uri, params, headers) {
      @mock.post JSON.parse(params)
    } do
      Discord::Notifier.message "String Message", @custom_config
    end

    @mock.verify
  end

  def test_multiple_embeds
    expected_payload = {
      url: 'http://test.com',
      username: 'Gem Test',
      avatar_url: 'http://avatar.com/discord.png',
      embeds: [
        {
          title: 'Embed Message Test',
          description: 'Sending an embed through Discord Notifier',
          url: 'http://github.com/ianmitchell/discord_notifier',
        },
        {
          title: 'Second Embed Message Test',
          description: 'Sending an embed through Discord Notifier',
          url: 'http://github.com/ianmitchell/discord_notifier',
        }
      ]
    }.to_json

    @mock = Minitest::Mock.new
    @mock.expect(:post, true, [JSON.parse(expected_payload)])

    Discord::Notifier.setup do |config|
      config.url = 'http://test.com'
      config.username = 'Gem Test'
      config.avatar_url = 'http://avatar.com/discord.png'
    end

    Net::HTTP.stub :post, ->(uri, params, headers) {
      @mock.post JSON.parse(params)
    } do
      embed_one = Discord::Embed.new do
        title 'Embed Message Test'
        description 'Sending an embed through Discord Notifier'
        url 'http://github.com/ianmitchell/discord_notifier'
      end

      embed_two = Discord::Embed.new do
        title 'Second Embed Message Test'
        description 'Sending an embed through Discord Notifier'
        url 'http://github.com/ianmitchell/discord_notifier'
      end

      Discord::Notifier.message [embed_one, embed_two]
    end

    @mock.verify
  end

  def test_incorrect_message_type
    assert_raises ArgumentError do
      Discord::Notifier.message 42
    end
  end

  def test_endpoint
    endpoint = Discord::Notifier.endpoint(url: 'http://test.com')
    assert endpoint.eql? URI('http://test.com')

    endpoint = Discord::Notifier.endpoint(url: 'http://test.com', wait: true)
    assert endpoint.eql? URI('http://test.com?wait=true')
  end
end