class User < ActiveRecord::Base
  has_many :installations, dependent: :delete_all
  has_many :api_keys, dependent: :delete_all

  has_secure_password

  after_create :create_api_key

  def reset_password!
    self.password = rand_password=('0'..'z').to_a.shuffle.first(6).join
    self.password_confirmation = self.password

    save!

    # TODO: send password reset email
    # DefaultMailer.password_reset(self, self.password)
  end

private

  def create_api_key
    ApiKey.create(user: self)
  end
end
