class PageController < ApplicationController
  before_filter :authenticate_user!, :except => [:index]
  before_filter :authorize_user!, :only => :paid_content

  def paid_content
  end

  def protected
  end

  def index
  end
end
