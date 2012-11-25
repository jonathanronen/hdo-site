class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable,
         :recoverable,
         :rememberable,
         :trackable,
         :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :role

  has_many :last_updated_issues, foreign_key: 'last_updated_by_id', class_name: 'Issue'
  has_many :issues, foreign_key: 'editor_id', order: :title

  ROLES = %w[admin superadmin]
  validates :role, presence: true, inclusion: { in: ROLES }

  def self.allowed(object, subject)
    rules = []
    return rules unless subject.kind_of?(self) || subject == self

    rules << :edit if object.superadmin?

    rules
  end

  def admin?
    role == 'admin'
  end

  def superadmin?
    role == 'superadmin'
  end

  def first_name
    name.split(' ').first
  end

  def percentage_of_issues
    issues.size * 100 / Issue.count
  end
end
