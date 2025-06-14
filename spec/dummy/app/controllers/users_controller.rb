# frozen_string_literal: true

class UsersController < ApplicationController
  include BulkOperationsable
  include DatabaseResettable

  before_action :initialize_repositories
  before_action :set_user, only: %i[show edit update destroy toggle_active]

  def index
    pagination = PaginationConfig.from_params(params)
    @users = user_repository.paginated(limit: pagination.limit, offset: pagination.offset)
    @total_users = user_repository.count
    @active_users = user_repository.active_users.count
  end

  def show
    @posts = post_repository.user_posts(@user)
    @comments = @user.comments.includes(:post).order(created_at: :desc).limit(10)
  end

  def new
    @form = UserCreationForm.new
    @roles = Role.all
  end

  def create
    @form = UserCreationForm.new(user_creation_params)

    if @form.submit
      redirect_to @form.user, notice: "User created successfully."
    else
      @roles = Role.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @user.build_profile unless @user.profile
    @roles = Role.all
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: "User updated successfully."
    else
      @roles = Role.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    name = @user.name
    @user.destroy
    redirect_to users_url, notice: "User '#{name}' and all associated records deleted successfully."
  end

  def toggle_active
    @user.update!(active: !@user.active)
    status = @user.active? ? "activated" : "deactivated"
    redirect_to @user, notice: "User #{status} successfully."
  end

  # Bulk operations for testing DBWatcher
  def bulk_update
    perform_bulk_operation(:update, params[:user_ids], params)
  end

  def bulk_delete
    perform_bulk_operation(:delete, params[:user_ids])
  end

  def reset_data
    reset_database
  end

  private

  def initialize_repositories
    @user_repository = UserRepository.new
    @post_repository = PostRepository.new
  end

  attr_reader :user_repository, :post_repository

  def set_user
    @user = user_repository.find(params[:id])
  end

  def user_creation_params
    params.require(:user_creation_form).permit(
      :name, :email, :age, :active, :salary, :birth_date, :notes, :preferences,
      :first_name, :last_name, :bio, :website, :location, :avatar_url
    )
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :age, :active, :salary, :birth_date, :notes, :preferences,
      profile_attributes: %i[id first_name last_name bio website location avatar_url]
    )
  end
end
