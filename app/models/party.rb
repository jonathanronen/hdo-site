class Party < ActiveRecord::Base
  extend FriendlyId

  include Hdo::Model::HasFallbackImage

  include Tire::Model::Search
  include Tire::Model::Callbacks

  tire.settings(TireSettings.default) {
    mapping {
      indexes :name, type: :string, boost: 20
      indexes :slug, type: :string, boost: 20
    }
  }

  has_many :governing_periods,  dependent: :destroy, order: :start_date
  has_many :party_memberships,  dependent: :destroy
  has_many :representatives,    through:   :party_memberships

  has_and_belongs_to_many :promises, uniq: true

  validates :name,        presence: true, uniqueness: true
  validates :external_id, presence: true, uniqueness: true

  friendly_id :external_id, use: :slugged

  image_accessor :image
  attr_accessible :image, :name

  def self.in_government
    today = Date.today

    joins(:governing_periods).
      where("start_date <= ? AND (end_date >= ? or end_date IS NULL)", today, today)
  end

  def in_government?(date = Date.today)
    governing_periods.for_date(date).any?
  end

  def large_logo
    image_with_fallback.strip.url
  end

  def tiny_logo
    image_with_fallback.thumb("28x28").strip.url
  end

  def default_image
    default_logo = Rails.root.join("app/assets/images/party-logos/unknown.png")
    large_logo = Rails.root.join("app/assets/images/party-logos/#{URI.encode slug}.png")

    large_logo.exist? ? large_logo : default_logo
  end

  def current_representatives
    representatives_at Date.today
  end

  def representatives_at(date)
    party_memberships.includes(:representative).for_date(date).map { |e| e.representative }.sort_by { |e| e.last_name }
  end
end
