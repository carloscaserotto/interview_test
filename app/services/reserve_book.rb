class ReserveBook
  Result = Struct.new(:success?, :reservation, :error)

  def initialize(book, email)
    @book = book
    @email = email
  end

  def call
    Book.transaction do
      @book.lock!
      return failure("Book is not available") unless @book.available?

      reservation = @book.reservations.create!(email: @email)
      @book.reserved!
      Result.new(true, reservation, nil)
    end
  rescue ActiveRecord::RecordInvalid => e
    failure(e.message)
  end

  private

  def failure(msg)
    Result.new(false, nil, msg)
  end
end