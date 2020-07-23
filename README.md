
# API with Rails and Vue JS on the Frontend

* Create a new project with api option
```sh
$ rails new recordstore-back --api
```
Note: uncomment redis, bcrypt and rack-cors gems in the gemfile, then add jwt_sessions to the gemfile

* Now we need to generate a model
```sh
$ rails g model User email password_digest
```

After is the model is generated we need to modify the migration file especific
the email field in order to be require by the User, in my case my migration is 20200710192036_create_users.rb and below is
my code with the change.

```ruby
class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :password_digest

      t.timestamps
    end
  end
end
```
Just add null: false to email field and that'w it.

After you make the change just execute the migrate rails command like this:
$ railg db:migrate

Now in app/models/user.rb we need to add the folliwing.
```ruby
class User < ApplicationRecord
  has_secure_password
end
```
Now is time to generate a scaffold for Artist by the following rails command.
$rails g scaffold Artist name:string user:references

The again we need to migrate in order to have those changes.
$rails db:migrate

Now we need to generate a scaffold for Record by the following rails command.
$rails g scaffold Record title:string year:string artist:references user:references

After we generate the Record scaffold proceed to migrate again
$rails db:migrate

Now we need create a namespace of api inside of our controllers directory, meaning you need to create those
manually like this
```sh
├───api
│   └───v1

```
Then inside v1 folder move  artist_controller.rb and record_controller.rb and for both files add module api>module V1,
here is and example in artist_controller.rb:
```ruby
module Api
  module V1
    class ArtistsController < ApplicationController
      before_action :set_artist, only: [:show, :update, :destroy]

      # GET /artists
      def index
        @artists = Artist.all

        render json: @artists
      end

      # GET /artists/1
      def show
        render json: @artist
      end

      # POST /artists
      def create
        @artist = Artist.new(artist_params)

        if @artist.save
          render json: @artist, status: :created, location: @artist
        else
          render json: @artist.errors, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /artists/1
      def update
        if @artist.update(artist_params)
          render json: @artist
        else
          render json: @artist.errors, status: :unprocessable_entity
        end
      end

      # DELETE /artists/1
      def destroy
        @artist.destroy
      end

      private
        # Use callbacks to share common setup or constraints between actions.
        def set_artist
          @artist = Artist.find(params[:id])
        end

        # Only allow a trusted parameter "white list" through.
        def artist_params
          params.require(:artist).permit(:name, :user_id)
        end
    end
  end
end

```
You need to do it for both files.

Now we need to do our relations for user, record, artist as following.
```ruby
#user
class User < ApplicationRecord
  has_secure_password
  has_many :records
end
```
```ruby
#record
class Record < ApplicationRecord
  belongs_to :user

  validates :title, :year, presence: true
end
```
```ruby
#artist
class Record < ApplicationRecord
  belongs_to :user

  validates :title, :year, presence: true
end

```

Next step is configure our routes.rb file as following
```ruby
Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :records
      resources :artists
    end
  end
  
  root to: "home#index"

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
```

As you can see I add root to the routes.rb files so we need to create the home controller (home_controller.rb) 
manually in our controllers folder
```ruby
#home_controller.rb
class HomeController < ApplicationController
  def index
  end
end
```

# JWT sessions
For this session we need to set up our application_controller.rb file and add the following, this is the same as in the 
JWT documentation.
```ruby
#application_controller.rb
class ApplicationController < ActionController::API
  include JWTSessions::RailsAuthorization
  rescue_from JWTSessions::Errors::Unauthorize, with :not_authorized

  private
    def current_user
      @current_user ||= User.find(payload['user_id'])
    end

    def not_authorized
      render json: { error: 'Not authorized' }, status: :unauthorized
    end
end
```
Basically this code is a setup for Autherization session to our API via JWTSessions.
After we add this code to our application_controller.rb we need to create a jwt_session.rb file in the config/initializers
directory and add the folliwing code.
```ruby
#jwt_sessions
JWTSession.encryption_key = 'secret'
```
Now we need to do some set up in cors.rb file inside config/initializers to tell where is our origin server, your file
needs to look like this
```ruby
# cors.rb
# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin AJAX requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins 'http://localhost:8081'

    resource '*',
      headers: :any,
      credentials: true,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
```
Just uncomment line 7 to the end and add localhost:8081 and credentials: true.