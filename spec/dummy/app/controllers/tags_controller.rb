# frozen_string_literal: true

class TagsController < ApplicationController
  before_action :set_tag, only: %i[edit update destroy]

  def index
    @tags = Tag.includes(:posts).order(:name)
    @tag_stats = calculate_tag_statistics
  end

  def new
    @tag = Tag.new
  end

  def create
    @tag = Tag.new(tag_params)

    if @tag.save
      redirect_to tags_path, notice: "Tag '#{@tag.name}' was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @tag.update(tag_params)
      redirect_to tags_path, notice: "Tag '#{@tag.name}' was updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    tag_name = @tag.name
    posts_count = @tag.posts.count

    @tag.destroy

    redirect_to tags_path,
                notice: "Tag '#{tag_name}' was deleted successfully. #{posts_count} posts were untagged."
  end

  private

  def set_tag
    @tag = Tag.find(params[:id])
  end

  def tag_params
    params.require(:tag).permit(:name, :color, :description)
  end

  def calculate_tag_statistics
    {
      total: Tag.count,
      with_posts: Tag.joins(:posts).distinct.count,
      most_used: Tag.joins(:posts).group("tags.id").order("COUNT(posts.id) DESC").limit(5)
    }
  end
end
