class Badge < ApplicationRecord
  has_many :actions
  BADGE_TYPES = %i(
    bad
    good
    legendary
  )
  enum badge_type: BADGE_TYPES
  # name
  # description
  # icon_url
  # badge_type

  def new?
    # check if a new badge is needed

    # sign up

  end

  def self.find_by_type(type)
    badges = Badge.where(badge_type: type)
    # remove any duplicates
    array = badges.group_by { |b| b.name }.values.map do |group|
      if group.size > 1
        sorted_group = group.sort_by { |b| -b.threshold }
        [sorted_group.first]
      else
        group
      end
    end
    array.flatten
  end

  def self.all_names
    Badge.all.map do |badge|
      badge.name
    end
  end

  def self.generate_for(action)
    count = action.total_count_of_this_action_for_user
    badges = Badge.order('threshold DESC').where('trigger = ? AND threshold <= ?', action.name, count)
    return false if badges.empty?
    # special badges
    case action.name
    when 'add_car'
      # we have 2 actions for car, we should check if the car that is added has less than 20 mpg to be considered dirty
      if action.car.mpg <= 30
        # generate dirty badge
        badges.find_by(name: 'Pig Driver')
      else
        # generate nice car badge
        badges.find_by(name: 'Friendly Neighbourhood Car')
      end
    else
      badges.first
    end
  end
end
