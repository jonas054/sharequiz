require 'digest/sha1'

# This class represents a user account for someone using the
# system. It handles login with password. The administrator is a user
# and has the name "admin". The special privileges afforded to the
# admin are implemented in code and are based on the user having the
# name "admin".
class User < ActiveRecord::Base
  has_many :knowledges

  validates_presence_of     :name
  validates_uniqueness_of   :name

  attr_accessor :password_confirmation
  validates_confirmation_of :password

  validates_numericality_of :quiz_length, :greater_than => 0
  validates_numericality_of :goal,        :greater_than => 0
  
  def validate
    errors.add_to_base "Missing password" if hashed_password.blank?
  end

  def self.authenticate(name, password)
    user = find_by_name(name) or return nil
    user if encrypted_password(password, user.salt) == user.hashed_password
  end

  attr_reader :password

  def password=(pwd)
    @password = pwd
    self.salt = object_id.to_s + rand.to_s
    self.hashed_password = User.encrypted_password password, salt
  end

  def after_destroy
    raise "Can't delete last user" if User.count.zero?
  end

  def self.lesson_owners
    find(:all,
         :joins      => ", lessons",
         :conditions => "lessons.user_id = users.id").uniq.
      map { |u| u.name }.sort
  end
  
  private

  def self.encrypted_password(password, salt)
    Digest::SHA1.hexdigest password + "wibble" + salt
  end
end
