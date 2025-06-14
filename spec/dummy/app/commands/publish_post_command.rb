# frozen_string_literal: true

# Command for publishing posts with business logic
class PublishPostCommand < ApplicationCommand
  def initialize(post_id)
    super()
    @post_id = post_id
  end

  def call
    post = find_post
    return failure("Post not found") unless post

    return failure("Post cannot be published") unless post.can_be_published?

    if publish_post(post)
      success(post, "Post '#{post.title}' published successfully")
    else
      failure("Failed to publish post", post.errors.full_messages)
    end
  end

  private

  attr_reader :post_id

  def find_post
    Post.find_by(id: post_id)
  end

  def publish_post(post)
    post.update(
      status: :published,
      published_at: Time.current
    )
  end
end
