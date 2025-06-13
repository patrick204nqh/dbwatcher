# frozen_string_literal: true

class CreateInitialModels < ActiveRecord::Migration[8.0]
  def change
    create_users_table
    create_profiles_table
    create_roles_table
    create_user_roles_table
    create_tags_table
    create_posts_table
    create_comments_table
    create_post_tags_table
    add_user_login_count
  end

  private

  def create_users_table
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
  end

  def create_profiles_table
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.text :bio
      t.string :website
      t.string :location
      t.string :avatar_url

      t.timestamps
      t.index [:user_id], name: "index_profiles_on_user_id"
    end
  end

  def create_roles_table
    create_table :roles do |t|
      t.string :name, null: false
      t.text :description
      t.json :permissions

      t.timestamps
      t.index [:name], name: "index_roles_on_name", unique: true
    end
  end

  def create_user_roles_table
    create_table :user_roles do |t|
      t.references :user, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.datetime :assigned_at

      t.timestamps
      t.index %i[user_id role_id], unique: true
    end
  end

  def create_tags_table
    create_table :tags do |t|
      t.string :name, null: false
      t.string :slug
      t.string :color, default: "#blue"
      t.text :description

      t.timestamps
      t.index [:name], name: "index_tags_on_name", unique: true
      t.index [:slug], name: "index_tags_on_slug", unique: true
    end
  end

  def create_posts_table
    create_table :posts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content
      t.text :excerpt
      t.integer :status, default: 0 # enum: draft, published, archived
      t.boolean :featured, default: false
      t.datetime :published_at
      t.integer :views_count, default: 0

      t.timestamps
      t.index [:user_id]
      t.index %i[status published_at]
      t.index [:featured]
    end
  end

  def create_comments_table
    create_table :comments do |t|
      t.references :post, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true
      t.references :parent, null: true, foreign_key: { to_table: :comments }
      t.text :content, null: false
      t.boolean :approved, default: false

      t.timestamps
      t.index %i[post_id approved]
      t.index [:parent_id]
    end
  end

  def create_post_tags_table
    create_table :post_tags do |t|
      t.references :post, null: false, foreign_key: true
      t.references :tag, null: false, foreign_key: true

      t.timestamps
      t.index %i[post_id tag_id], unique: true
    end
  end

  def add_user_login_count
    add_column :users, :last_login_count, :integer, default: 0
  end
end
