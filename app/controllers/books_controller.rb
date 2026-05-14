class BooksController < ApplicationController
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