class BooksController < ApplicationController
  def index
    page = (params[:page] || 1).to_i
    per_page = (params[:per_page] || 25).to_i

    books = Book.includes(:reservations)
    books = books.where(status: params[:status]) if params[:status].present?
    books = books.order(:id).offset((page - 1) * per_page).limit(per_page)

    render json: books.as_json(include: :reservations)
  end

  def show
    book = Book.includes(:reservations).find(params[:id])
    render json: book.as_json(include: :reservations)
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Book not found" }, status: :not_found
  end

  def reserve
    book = Book.find(params[:id])
    result = ReserveBook.new(book, reservation_params[:email]).call

    if result.success?
      render json: result.reservation, status: :created
    else
      render json: { error: result.error }, status: :unprocessable_entity
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Book not found" }, status: :not_found
  end

  private

  def reservation_params
    params.require(:reservation).permit(:email)
  end
end
