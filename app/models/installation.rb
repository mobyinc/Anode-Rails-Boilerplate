class Installation < ActiveRecord::Base
  belongs_to :user

  validates :user_id, :device_token, presence: true
end
