class BooksController < ApplicationController
  MAX_PAGE_SIZE = 100
  DEFAULT_PAGE_SIZE = 25

  def index
    filtered = Book.by_status(params[:status]).search_title(params[:q])

    page = [params[:page].to_i, 1].max
    per_page = [[params[:per_page].to_i, 1].max, MAX_PAGE_SIZE].min
    per_page = DEFAULT_PAGE_SIZE if params[:per_page].blank?

    total = filtered.count
    books = filtered
      .select(:id, :title, :status, :reservations_count, :updated_at)
      .order(:id)
      .offset((page - 1) * per_page)
      .limit(per_page)
      .to_a

    set_pagination_headers(total: total, page: page, per_page: per_page)

    if stale?(etag: [books.map { |b| [b.id, b.updated_at.to_i] }, total], public: true)
      render json: books.map { |b| serialize_book(b) }
    end
  end

  def show
    book = Book.includes(:reservations).find(params[:id])

    if stale?(book, public: true)
      render json: serialize_book(book, include_reservations: true)
    end
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

  def serialize_book(book, include_reservations: false)
    payload = {
      id: book.id,
      title: book.title,
      status: book.status,
      reservations_count: book.reservations_count
    }

    if include_reservations
      payload[:reservations] = book.reservations.map do |r|
        { id: r.id, email: r.email, created_at: r.created_at }
      end
    end

    payload
  end

  def set_pagination_headers(total:, page:, per_page:)
    response.set_header("X-Total-Count", total.to_s)
    response.set_header("X-Page", page.to_s)
    response.set_header("X-Per-Page", per_page.to_s)
    response.set_header("X-Total-Pages", (total.to_f / per_page).ceil.to_s)
  end
end
