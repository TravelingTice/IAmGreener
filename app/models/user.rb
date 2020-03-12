class User < ApplicationRecord
  attr_writer :login

  validates :username, presence: :true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true

  has_many :notifications

  has_many :actions

  # friends association
  has_many :friendships
  has_many :friends, through: :friendships
  has_many :inverse_friendships, class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :inverse_friends, through: :inverse_friendships, source: :user

  # Include default devise modules. Others available are:
  has_one_attached :avatar# Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # login
  def self.find_for_database_authentication(warden_conditions)
    conditions = warden_conditions.dup
    if login = conditions.delete(:login)
      where(conditions.to_h).where(["lower(username) = :value OR lower(email) = :value", { :value => login.downcase }]).first
    elsif conditions.has_key?(:username) || conditions.has_key?(:email)
      where(conditions.to_h).first
    end
  end

  def login
    @login || self.username || self.email
  end

  # actions
  def actions_from_day(date)
    self.actions.where("DATE(created_at) = ?", date)
  end

  # trees
  def trees
    # get all trees from user
    self.actions.where(name: 3).sum(:count)
  end

  def trees_on_day(date)
    # get the sum of the total amount of trees on a certain day
    actions_from_day(date).where(name: 3).sum(:count)
  end

  def trees_by_day_this_week
    # get the trees from this past week in an array
    # get week day nr (sunday: 1, saturday: 7)
    week_day = Time.now().wday;
    trees_arr = [0, 0, 0, 0, 0, 0, 0]
    (0..week_day).each do |i|
      trees_arr[i] = trees_on_day((week_day - i).days.ago)
    end
    trees_arr
  end

  # challenges
  def todays_challenge
    # check if Action 'new_daily_challenge' is already there for today
    action = actions.where(name: 4).find_by("DATE(created_at) = ?", Date.today)
    if action.nil?
      Action.create(user: self, name: "new_daily_challenge", challenge: Challenge.all.sample, count: 1)
    else
      action.challenge
    end
  end

  def todays_challenge_completed?
    action = self.actions_from_day(Date.today).find_by(name: 5, challenge: todays_challenge)
    !action.nil?
  end

  def challenge_completed?(challenge)
    actions = self.actions.where(challenge: challenge, name: 5)
    !actions.empty?
  end

  # friends
  def friends_with?(friend)
    # select all friendships that are accepted
    accepted_friendship = Friendship.find_by(user: self, friend: friend, accepted: true)
    !accepted_friendship.nil?
  end

  def requested?(friend)
    requested_friendship = Friendship.find_by(user: self, friend: friend, accepted: false)
    !requested_friendship.nil?
  end

  # filters
  def self.by_name(name)
    where("username ILIKE ?", "%#{name}%")
  end

  # badges
  def all_badges
    self.actions.includes(:badge).where(name: 'collect_badge').map { |a| a.badge }
    # Badge.joins(:actions).where('action.name = ?, action.user_id: ?', 'collect_badge', self.id)
    # badges = self.actions.where(name: 7).references(:badge)
    # byebug
  end

  def badges
    # all_badges.group_by(:name)
  end

  def has_badge?(badge)
    badges.include?(badge)
  end

  def is_collected?(badge)
    # find an action with name collect_badge and this badge
    actions = self.actions.where(name: 7, badge: badge)
    !actions.empty?
  end

  def to_be_collected
    # list all badges that are yet to be collected
    # check if there was any actions with 'earn badge' AFTER the last 'collect badge'
    badge_actions = self.actions.order('created_at DESC').where(name: 6)
    to_be_collected = []
    badge_actions.each do |action|
      if is_collected?(action.badge)
        to_be_collected << action.badge
      end
    end
    # return sorted from big to small
    to_be_collected.uniq
  end
end
