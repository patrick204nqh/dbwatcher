# frozen_string_literal: true

class CreateInitialModels < ActiveRecord::Migration[8.0]
  def change
    # Users table with various data types for comprehensive testing
    create_table :users do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.integer :age
      t.boolean :active, default: true
      t.decimal :salary, precision: 10, scale: 2
      t.date :birth_date
      t.datetime :last_login_at
      t.json :preferences
      t.text :notes

      t.timestamps
      t.index :email, unique: true
      t.index %i[active age]
    end

    # Profiles table (one-to-one with users)
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.text :bio
      t.string :website
      t.string :location
      t.string :avatar_url

      t.timestamps
    end

    # Posts table (one-to-many with users)
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.text :excerpt
      t.integer :status, default: 0 # enum: draft=0, published=1, archived=2
      t.integer :views_count, default: 0
      t.boolean :featured, default: false
      t.datetime :published_at

      t.timestamps
      t.index %i[user_id status]
      t.index :published_at
    end

    # Comments table (many-to-many with users and posts, self-referential)
    create_table :comments do |t|
      t.references :user, null: false, foreign_key: true
      t.references :post, null: false, foreign_key: true
      t.references :parent, foreign_key: { to_table: :comments }, null: true
      t.text :content, null: false
      t.boolean :approved, default: false

      t.timestamps
      t.index %i[post_id approved]
    end

    # Tags table for many-to-many relationship
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug
      t.string :color, default: "#blue"
      t.text :description

      t.timestamps
      t.index :name, unique: true
      t.index :slug, unique: true
    end

    # Join table for posts and tags
    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
      t.index %i[post_id tag_id], unique: true
    end

    # Roles table for user permissions
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description
      t.json :permissions

      t.timestamps
      t.index :name, unique: true
    end

    # Join table for users and roles
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.datetime :assigned_at, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
      t.index %i[user_id role_id], unique: true
    end
  end
end
