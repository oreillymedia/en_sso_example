class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable,
         :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  def self.find_for_open_id(access_token, signed_in_resource=nil)
    data = access_token.info
    if user = User.where(:email => data["email"]).first
      user
    else
      User.create!({
        :email => data["email"],
        :identity_url => access_token.uid,
        :password => Devise.friendly_token[0,20],
      # Bypass mass assignment protection for :identity_url because
      # we are specifically selecting attributes for inclusion in the hash.
      }, :without_protection => true)
    end
  end

  def identity_guid
    # Assumes the O'Reilly identity_url format
    guid_re =
      /([0-9a-f]{8}-
        [0-9a-f]{4}-
        [0-9a-f]{4}-
        [0-9a-f]{4}-
        [0-9a-f]{12})/x
    m = guid_re.match(identity_url)
    m[1] if m
  end
end
