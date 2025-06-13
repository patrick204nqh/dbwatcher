# frozen_string_literal: true

class RolesController < ApplicationController
  before_action :set_role, only: %i[edit update destroy]

  def index
    @roles = Role.includes(:users).order(:name)
    @role_stats = {
      total: Role.count,
      with_users: Role.joins(:users).distinct.count,
      user_assignments: UserRole.count
    }
  end

  def new
    @role = Role.new
  end

  def create
    @role = Role.new(role_params)

    if @role.save
      redirect_to roles_path, notice: "Role '#{@role.name}' was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @role.update(role_params)
      redirect_to roles_path, notice: "Role '#{@role.name}' was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    role_name = @role.name
    users_count = @role.users.count

    if users_count > 0
      redirect_to roles_path,
                  alert: "Cannot delete role '#{role_name}' because it is assigned to #{users_count} users."
    else
      @role.destroy
      redirect_to roles_path, notice: "Role '#{role_name}' was deleted successfully."
    end
  end

  private

  def set_role
    @role = Role.find(params[:id])
  end

  def role_params
    params.require(:role).permit(:name, :description, :permissions)
  end
end
