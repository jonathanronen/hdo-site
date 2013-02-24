class User < ActiveRecord::Base
  extend FriendlyId

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  friendly_id :external_id, use: :slugged

  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :role
end
