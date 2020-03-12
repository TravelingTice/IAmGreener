class ActionsController < ApplicationController
  def create
    badge = Badge.find(params[:badge_id])
    action = Action.new(count: 1, badge: badge, name: params[:name], user: current_user)
    if action.save
      redirect_to dashboard_path
    end
  end

  def create_for_completed_challenge
    unless params[:status] == 'not_possible' || params[:status] == 'not_completed'
    action = Action.new(count: 35, name: "earn_tree", user: current_user)
    action.save
    redirect_to challenges_completed_path
  else
    redirect_to challenges_failed_path
    end
  end
end
