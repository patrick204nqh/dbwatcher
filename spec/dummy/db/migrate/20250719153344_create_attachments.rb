class CreateAttachments < ActiveRecord::Migration[8.0]
  def change
    create_table :attachments do |t|
      t.references :attachable, polymorphic: true, null: false
      t.references :user, null: true, foreign_key: true
      t.string :filename
      t.string :content_type
      t.integer :file_size
      t.string :attachment_type
      t.string :url
      t.json :metadata

      t.timestamps
    end
  end
end
