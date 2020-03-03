class HomesController < ApplicationController
  def new
    @home = Home.new
  end

  def create
    @home = Home.new(home_params)
    @home.user = current_user
    if @home.save
      redirect_to root_path
    else
      render :new
    end
  end

  private
    def home_params
      params.require(:home).permit(:location, :type, :isolation_type, :inhabitants_size, :score)
    end
end
