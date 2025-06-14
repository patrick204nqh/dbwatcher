# frozen_string_literal: true

class PostsController < ApplicationController
  include Statisticsable

  before_action :initialize_repositories
  before_action :set_post, only: %i[show edit update destroy publish archive increment_views]
  before_action :set_user, only: %i[new create], if: -> { params[:user_id].present? }

  def index
    pagination = PaginationConfig.from_params(params)
    @posts = post_repository.paginated(limit: pagination.limit, offset: pagination.offset)
    @featured_posts = post_repository.featured.limit(5)
    @recent_posts = post_repository.recent(1.week.ago).count
  end

  def show
    @comments = load_post_comments
    @new_comment = Comment.new
  end

  def new
    @post = build_new_post
    @post.tags.build
  end

  def create
    @post = build_new_post(post_params)

    if @post.save
      handle_tags
      redirect_to @post, notice: "Post created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @post.update(post_params)
      handle_tags
      redirect_to @post, notice: "Post updated successfully."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    redirect_to posts_url, notice: "Post deleted successfully."
  end

  def publish
    @post.update!(status: :published, published_at: Time.current)
    redirect_to @post, notice: "Post published successfully."
  end

  def archive
    @post.update!(status: :archived)
    redirect_to @post, notice: "Post archived successfully."
  end

  def increment_views
    @post.increment!(:views_count)
    render json: { views_count: @post.views_count }
  end

  private

  def initialize_repositories
    @post_repository = PostRepository.new
    @user_repository = UserRepository.new
  end

  attr_reader :post_repository, :user_repository

  def set_post
    @post = post_repository.find(params[:id])
  end

  def set_user
    @user = user_repository.find(params[:user_id])
  end

  def post_params
    params.require(:post).permit(:title, :content, :excerpt, :status, :featured, :published_at, tag_ids: [])
  end

  def load_post_comments
    @post.comments.includes(:user, :replies)
         .where(parent_id: nil)
         .order(created_at: :desc)
         .limit(20)
  end

  def build_new_post(attributes = {})
    if @user
      @user.posts.build(attributes)
    else
      Post.new(attributes.merge(user: current_user_for_testing))
    end
  end

  def handle_tags
    return unless params[:tag_names].present?

    tag_names = parse_tag_names
    tags = create_or_find_tags(tag_names)
    @post.tags = tags
  end

  def parse_tag_names
    params[:tag_names].split(",").map(&:strip).reject(&:blank?)
  end

  def create_or_find_tags(tag_names)
    tag_names.map do |name|
      Tag.find_or_create_by(name: name) do |tag|
        tag.slug = name.downcase.gsub(/[^a-z0-9]+/, "-")
        tag.color = ["#red", "#blue", "#green", "#purple", "#orange"].sample
      end
    end
  end

  def current_user_for_testing
    # For testing purposes, use first user or create one
    User.first || User.create!(
      name: "Test User",
      email: "test_#{Time.current.to_i}@example.com",
      age: 30
    )
  end
end
