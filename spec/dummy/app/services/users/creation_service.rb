# frozen_string_literal: true

module Users
  # Service for handling user creation with associated records
  class CreationService < ApplicationService
    def initialize(user_params)
      super()
      @user_params = user_params
    end

    def call
      ActiveRecord::Base.transaction do
        create_user_with_associations
      end
    rescue ActiveRecord::RecordInvalid => e
      failure("Failed to create user: #{e.message}", e.record.errors)
    end

    private

    attr_reader :user_params

    def create_user_with_associations
      user = User.new(user_params)

      if user.save
        assign_default_role(user)
        success(user, "User created successfully")
      else
        failure("Failed to create user", user.errors)
      end
    end

    def assign_default_role(user)
      default_role = Role.find_by(name: "User")
      return unless default_role

      user.user_roles.create!(role: default_role)
    end
  end
end
