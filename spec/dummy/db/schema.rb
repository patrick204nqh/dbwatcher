# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_07_19_153344) do
  create_table "admin_users", force: :cascade do |t|
    t.string "username", null: false
    t.string "email", null: false
    t.boolean "super_admin", default: false
    t.string "department"
    t.datetime "last_access_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_admin_users_on_email", unique: true
    t.index ["username"], name: "index_admin_users_on_username", unique: true
  end

  create_table "attachments", force: :cascade do |t|
    t.string "attachable_type", null: false
    t.integer "attachable_id", null: false
    t.integer "user_id"
    t.string "filename"
    t.string "content_type"
    t.integer "file_size"
    t.string "attachment_type"
    t.string "url"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["attachable_type", "attachable_id"], name: "index_attachments_on_attachable"
    t.index ["user_id"], name: "index_attachments_on_user_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.integer "user_id"
    t.string "action", null: false
    t.string "resource_type"
    t.integer "resource_id"
    t.json "changes"
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["resource_type", "resource_id"], name: "index_audit_logs_on_resource_type_and_resource_id"
    t.index ["user_id", "action"], name: "index_audit_logs_on_user_id_and_action"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "billing_accounts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "account_number", null: false
    t.string "billing_email"
    t.decimal "balance", precision: 10, scale: 2, default: "0.0"
    t.boolean "active", default: true
    t.date "trial_ends_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_number"], name: "index_billing_accounts_on_account_number", unique: true
    t.index ["user_id", "active"], name: "index_billing_accounts_on_user_id_and_active"
    t.index ["user_id"], name: "index_billing_accounts_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "categories_users", id: false, force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "category_id", null: false
  end

  create_table "comments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "post_id", null: false
    t.integer "parent_id"
    t.text "content", null: false
    t.boolean "approved", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parent_id"], name: "index_comments_on_parent_id"
    t.index ["post_id", "approved"], name: "index_comments_on_post_id_and_approved"
    t.index ["post_id"], name: "index_comments_on_post_id"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "old_orders", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "order_number", null: false
    t.decimal "total_amount", precision: 10, scale: 2
    t.integer "status", default: 0
    t.date "shipped_date"
    t.json "shipping_details"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["order_number"], name: "index_old_orders_on_order_number", unique: true
    t.index ["user_id", "status"], name: "index_old_orders_on_user_id_and_status"
    t.index ["user_id"], name: "index_old_orders_on_user_id"
  end

  create_table "post_tags", force: :cascade do |t|
    t.integer "post_id", null: false
    t.integer "tag_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["post_id", "tag_id"], name: "index_post_tags_on_post_id_and_tag_id", unique: true
    t.index ["post_id"], name: "index_post_tags_on_post_id"
    t.index ["tag_id"], name: "index_post_tags_on_tag_id"
  end

  create_table "posts", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.text "content", null: false
    t.text "excerpt"
    t.integer "status", default: 0
    t.integer "views_count", default: 0
    t.boolean "featured", default: false
    t.datetime "published_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["published_at"], name: "index_posts_on_published_at"
    t.index ["user_id", "status"], name: "index_posts_on_user_id_and_status"
    t.index ["user_id"], name: "index_posts_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "first_name"
    t.string "last_name"
    t.text "bio"
    t.string "website"
    t.string "location"
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.json "permissions"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name", unique: true
  end

  create_table "skills", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "tags", force: :cascade do |t|
    t.string "name", null: false
    t.string "slug"
    t.string "color", default: "#blue"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_tags_on_name", unique: true
    t.index ["slug"], name: "index_tags_on_slug", unique: true
  end

  create_table "test_users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.integer "age"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_roles", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "role_id", null: false
    t.datetime "assigned_at", default: -> { "CURRENT_TIMESTAMP" }
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_user_roles_on_role_id"
    t.index ["user_id", "role_id"], name: "index_user_roles_on_user_id_and_role_id", unique: true
    t.index ["user_id"], name: "index_user_roles_on_user_id"
  end

  create_table "user_skills", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "skill_id", null: false
    t.string "proficiency_level"
    t.integer "years_experience"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["skill_id"], name: "index_user_skills_on_skill_id"
    t.index ["user_id"], name: "index_user_skills_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.integer "age"
    t.boolean "active", default: true
    t.decimal "salary", precision: 10, scale: 2
    t.date "birth_date"
    t.datetime "last_login_at"
    t.json "preferences"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "last_login_count", default: 0
    t.index ["active", "age"], name: "index_users_on_active_and_age"
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  add_foreign_key "attachments", "users"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "billing_accounts", "users"
  add_foreign_key "comments", "comments", column: "parent_id"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users"
  add_foreign_key "old_orders", "users"
  add_foreign_key "post_tags", "posts"
  add_foreign_key "post_tags", "tags"
  add_foreign_key "posts", "users"
  add_foreign_key "profiles", "users"
  add_foreign_key "user_roles", "roles"
  add_foreign_key "user_roles", "users"
  add_foreign_key "user_skills", "skills"
  add_foreign_key "user_skills", "users"
end
