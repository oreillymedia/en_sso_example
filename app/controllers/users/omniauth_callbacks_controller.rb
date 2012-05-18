class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Avoid resetting session during callback so that Devise can redirect back to
  # the originally requested page.  This is really a GET request redirected
  # from the OpenID endpoint anyway, so we're never going to be able to receive
  # a token.
  skip_before_filter :verify_authenticity_token, :only => [:sso]

  def sso
    @user = User.find_for_open_id(request.env["omniauth.auth"], current_user)

    if @user.persisted?
      flash[:notice] = I18n.t "devise.omniauth_callbacks.success", :kind => "O'Reilly"
      sign_in_and_redirect @user, :event => :authentication
    else
      session["devise.sso_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  protected

  def after_omniauth_failure_path_for(scope)
    root_url
  end

  def failure_message
    if failed_strategy.extra["response"].status == :cancel
      "Authentication cancelled; is this app authorized to use O'Reilly OpenID?"
    else
      super
    end
  end
end
