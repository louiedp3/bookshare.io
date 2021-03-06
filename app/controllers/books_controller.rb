class BooksController < ApplicationController

  BOOKS_PER_PAGE=32

  respond_to :html, :json
  protect_from_forgery except: [:create]

  def index
    @books = Book.where(status: :avaliable).order("(ratings_count * average_rating) desc").page(params[:page]).per_page(BOOKS_PER_PAGE)
  end

  def category
    @category = Category.find(params[:id])
    @books    = @category.books.where(status: :avaliable).page(params[:page]).per_page(BOOKS_PER_PAGE)
    render :index
  end

  def categories
    @categories = Category.joins("JOIN books ON books.category_id = categories.id").where("books.status = 'avaliable'").group("categories.id")
  end

  def show
    @book = Book.find_by_isbn!(params[:isbn])
  end

  def create

    # TODO: Move token auth to a helper
    if params[:token].nil? || params[:token] != ENV['SECRET_TOKEN']
      return render status: 401, nothing: true
    end

    loader = BookLoader.new(params[:isbn], cover: :amazon, data: :google)
    loader.publish

    respond_with loader.book
  end

  def claim
    @book = Book.find_by_isbn!(params[:isbn])
    @item = Item.new(book_isbn: @book.isbn, order_id: @order.id)
    @item.save
    redirect_to book_path(@book.isbn)
  end

  def unclaim
    @item = @order.items.where(book_isbn: params[:isbn]).first
    @item.delete
    redirect_to book_path(params[:isbn])
  end

  def search
    @books = Book.text_search(params[:query])
  end

end
