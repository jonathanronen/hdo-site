class HdoUser < User
    has_many :last_updated_issues, foreign_key: 'last_updated_by_id', class_name: 'Issue'
  has_many :issues, foreign_key: 'editor_id', order: :title

  ROLES = %w[admin superadmin]
  validates :role, presence: true, inclusion: { in: ROLES }

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
    if Issue.count.zero?
      0
    else
      issues.size * 100 / Issue.count
    end
  end
end
