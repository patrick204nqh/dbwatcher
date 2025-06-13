# frozen_string_literal: true

class UsersController < ApplicationController
  before_action :set_user, only: %i[show edit update destroy toggle_active]

  def index
    @users = User.includes(:profile, :posts, :roles, :comments)
                 .order(created_at: :desc)
                 .limit(50)
    @total_users = User.count
    @active_users = User.where(active: true).count
  end

  def show
    @posts = @user.posts.includes(:tags, :comments).order(created_at: :desc).limit(10)
    @comments = @user.comments.includes(:post).order(created_at: :desc).limit(10)
  end

  def new
    @user = User.new
    @user.build_profile
    @roles = Role.all
  end

  def create
    @user = User.new(user_params)

    if @user.save
      assign_default_role
      redirect_to @user, notice: "User created successfully."
    else
      prepare_form_data
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
    user_ids = params[:user_ids] || []

    if user_ids.any?
      updated_count = perform_bulk_update(user_ids)
      redirect_to users_path, notice: "Updated #{updated_count} users."
    else
      redirect_to users_path, alert: "No users selected."
    end
  end

  def bulk_delete
    user_ids = params[:user_ids] || []

    if user_ids.any?
      deleted_count = perform_bulk_delete(user_ids)
      redirect_to users_path, notice: "Deleted #{deleted_count} users and their associated records."
    else
      redirect_to users_path, alert: "No users selected."
    end
  end

  def reset_data
    clear_all_data
    reseed_database
    redirect_to users_path, notice: "🔄 Database reset successful! All data refreshed to default state."
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(
      :name, :email, :age, :active, :salary, :birth_date, :notes, :preferences,
      profile_attributes: %i[id first_name last_name bio website location avatar_url]
    )
  end

  def assign_default_role
    default_role = Role.find_by(name: "User")
    @user.user_roles.create!(role: default_role) if default_role
  end

  def prepare_form_data
    @user.build_profile unless @user.profile
    @roles = Role.all
  end

  def perform_bulk_update(user_ids)
    User.where(id: user_ids).update_all(
      active: params[:active] == "true",
      updated_at: Time.current
    )
  end

  def perform_bulk_delete(user_ids)
    users_to_delete = User.where(id: user_ids)
    deleted_count = users_to_delete.count
    users_to_delete.destroy_all
    deleted_count
  end

  def clear_all_data
    [Comment, PostTag, Post, Profile, UserRole, User, Tag, Role].each(&:destroy_all)
  end

  def reseed_database
    load Rails.root.join("db", "seeds.rb")
  end
end
