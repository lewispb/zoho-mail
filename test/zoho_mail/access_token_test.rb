require "test_helper"

class ZohoMail::AccessTokenTest < ActiveSupport::TestCase
  setup do
    ZohoMail::AccessToken.unstub(:current)
    @previous_runtime_dir = ENV["XDG_RUNTIME_DIR"]
    ENV["XDG_RUNTIME_DIR"] = @runtime_dir = Dir.mktmpdir
  end

  teardown do
    ENV["XDG_RUNTIME_DIR"] = @previous_runtime_dir
    FileUtils.remove_entry(@runtime_dir)
  end

  test "requests an access token once and keeps it for later commands" do
    ZohoMail::OAuthClient.any_instance.expects(:access_token_for).with("test-refresh-token").once
      .returns(ZohoMail::AccessToken.new("fresh-access-token", 1.hour.from_now))

    assert_equal "fresh-access-token", ZohoMail::AccessToken.current.value
    assert_equal "fresh-access-token", ZohoMail::AccessToken.current.value
  end

  test "keeps the token in a file only this user can read" do
    ZohoMail::OAuthClient.any_instance.stubs(:access_token_for)
      .returns(ZohoMail::AccessToken.new("fresh-access-token", 1.hour.from_now))

    ZohoMail::AccessToken.current

    assert_equal 0o600, File.stat(ZohoMail::AccessToken.cache_path("test-refresh-token")).mode & 0o777
  end

  test "requests a new token when the kept one expires within the margin" do
    ZohoMail::AccessToken.new("expiring-access-token", 30.seconds.from_now).cache("test-refresh-token")
    ZohoMail::OAuthClient.any_instance.expects(:access_token_for)
      .returns(ZohoMail::AccessToken.new("fresh-access-token", 1.hour.from_now))

    assert_equal "fresh-access-token", ZohoMail::AccessToken.current.value
  end

  test "the file name does not contain the refresh token" do
    assert_no_match "test-refresh-token", ZohoMail::AccessToken.cache_path("test-refresh-token")
  end
end
