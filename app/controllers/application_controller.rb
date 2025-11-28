class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_up_path_for(_resource)
    new_month_path
  end
end
