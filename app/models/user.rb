class User < ApplicationRecord
  attr_writer :login

  validates :username, presence: :true, uniqueness: { case_sensitive: false }
  validates_format_of :username, with: /^[a-zA-Z0-9_\.]*$/, :multiline => true

  has_many :notifications
  has_many :actions
  has_many :profile_badges
  has_many :badges, through: :profile_badges

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

  def streak_count
    5
  end

  # actions
  def actions_from_day(date)
    actions = Action.where(user: self)
    actions.select do |action|
      action.created_at.strftime('%d-%m-%y') == date.strftime('%d-%m-%y')
    end
  end

  # trees
  def trees
    # get all trees from user
    actions.select do |action|
      action.earn_tree?
    end.map do |action|
      action.count
    end.sum
  end

  def trees_on_day(date)
    # get the sum of the total amount of trees on a certain day
    actions_from_day(date).select do |action|
      action.earn_tree?
    end.map do |action|
      action.count
    end.sum
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

  # progress
  def progress_from(date)
    puts "Progress from #{date}"
    {
      daily_challenge_completed?: false,
      daily_challenge: Challenge.all.sample
    }
  end

  def todays_progress
    progress_from(0.days.ago)
  end

  # challenges
  def todays_challenge
    Challenge.all.sample
  end

  def challenge_completed?
    false
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
    actions = Action.where(user: self, name: 'earn_badge')
    actions.map do |action|
      action.badge
    end
  end

  def badges
    badges = all_badges
    grouped = badges.group_by do |badge|
      badge.name
    end.values
    filtered = grouped.map do |group|
      if group.size > 1
        sorted_group = group.sort_by do |badge|
          -badge.threshold
        end
        sorted_group[0]
      else
        group
      end
    end
    filtered.flatten
  end

  def to_be_collected
    # list all badges that are yet to be collected
    # check if there was any actions with 'earn badge' AFTER the last 'collect badge'
    actions = Action.order('created_at DESC').where(user: self)
    to_be_collected = []
    actions.each do |action|
      break if action.collect_badge?
      to_be_collected << action.badge if action.earn_badge?
    end
    # return sorted from big to small
    to_be_collected.sort_by { |badge| badge.threshold }
  end
end
