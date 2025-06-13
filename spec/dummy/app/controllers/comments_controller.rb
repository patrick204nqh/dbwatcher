# frozen_string_literal: true

class CommentsController < ApplicationController
  before_action :set_post
  before_action :set_comment, only: %i[show edit update destroy]

  def create
    @comment = @post.comments.build(comment_params)

    if @comment.save
      redirect_to @post, notice: "Comment added successfully!"
    else
      redirect_to @post, alert: "Failed to add comment: #{@comment.errors.full_messages.join(", ")}"
    end
  end

  def edit
    # Simple edit form for testing
  end

  def update
    if @comment.update(comment_params)
      redirect_to @post, notice: "Comment updated successfully!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    redirect_to @post, notice: "Comment deleted successfully!"
  end

  private

  def set_post
    @post = Post.find(params[:post_id])
  end

  def set_comment
    @comment = @post.comments.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content, :user_id, :parent_id, :approved)
  end
end
