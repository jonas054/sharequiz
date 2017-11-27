require 'test_helper'

class UserTest < ActiveSupport::TestCase
  NAME = "Bob"
  PASSWORD = "1234"

  def setup
    @user = User.create! :name => NAME, :password => PASSWORD,
      :password_confirmation => PASSWORD
  end

  test "authenticate user ok" do
    assert_equal @user, User.authenticate(NAME, PASSWORD)
  end

  test "missing things" do
    check_save_errors User.new, ["Name can't be blank", "Missing password"]
  end

  test "default goal" do
    assert_equal 10, @user.goal
  end

  test "illegal goal" do
    check_save_errors(User.new(:name => 'Other user', :password => PASSWORD,
                               :password_confirmation => PASSWORD,
                               :goal => "x"),
                      ["Goal is not a number"])
    check_save_errors(User.new(:name => 'Other user', :password => PASSWORD,
                               :password_confirmation => PASSWORD,
                               :goal => "0"),
                      ["Goal must be greater than 0"])
  end
  
  test "duplicate name" do
    user2 = User.new :name => NAME, :password => "5678",
      :password_confirmation => "5678"
    check_save_errors user2, ["Name has already been taken"]
  end

  test "authenticate unknown user" do
    assert_nil User.authenticate("Unknown Guy", PASSWORD)
  end

  test "authenticate wrong password" do
    assert_nil User.authenticate(NAME, "aWrongPassword")
  end

  test "different passwords" do
    user = User.new :name => "New User", :password => "abc",
      :password_confirmation => "def"
    check_save_errors user, ["Password doesn't match confirmation"]
  end
end
