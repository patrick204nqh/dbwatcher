class Attachment < ApplicationRecord
  # Polymorphic association - can belong to any attachable model
  belongs_to :attachable, polymorphic: true
  
  # Optional: belongs to user who uploaded it
  belongs_to :user, optional: true
  
  validates :filename, presence: true
  validates :content_type, presence: true
  validates :file_size, presence: true, numericality: { greater_than: 0 }
  validates :attachment_type, inclusion: { in: %w[image document video audio] }
  
  scope :images, -> { where(attachment_type: 'image') }
  scope :documents, -> { where(attachment_type: 'document') }
  scope :videos, -> { where(attachment_type: 'video') }
  scope :audio, -> { where(attachment_type: 'audio') }
  
  def image?
    attachment_type == 'image'
  end
  
  def document?
    attachment_type == 'document'
  end
  
  def video?
    attachment_type == 'video'
  end
  
  def audio?
    attachment_type == 'audio'
  end
  
  def file_size_human
    if file_size < 1024
      "#{file_size} B"
    elsif file_size < 1024 * 1024
      "#{(file_size / 1024.0).round(1)} KB"
    else
      "#{(file_size / (1024.0 * 1024)).round(1)} MB"
    end
  end
end