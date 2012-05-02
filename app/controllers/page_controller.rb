class PageController < ApplicationController
  before_filter :authenticate_user!, :only => :protected

  def protected
  end

  def index
  end
end
