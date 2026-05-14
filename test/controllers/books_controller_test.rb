require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
  # ---------- reserve ----------
  test "should reserve book with valid email" do
    book = Book.create!(title: "Test Book 101", status: :available)

    post reserve_book_url(book), params: { reservation: { email: "test@example.com" } }
    assert_response :created

    assert_equal "reserved", book.reload.status
  end

  test "should not reserve a book that is already reserved" do
    book = Book.create!(title: "Already reserved", status: :reserved)

    post reserve_book_url(book), params: { reservation: { email: "test@example.com" } }
    assert_response :unprocessable_entity
  end

  test "should not reserve a book that is loaned" do
    book = Book.create!(title: "Loaned book", status: :loaned)

    post reserve_book_url(book), params: { reservation: { email: "test@example.com" } }
    assert_response :unprocessable_entity
  end

  test "returns 404 when reserving a missing book" do
    post reserve_book_url(id: 0), params: { reservation: { email: "test@example.com" } }
    assert_response :not_found
  end

  # ---------- index ----------
  test "GET /books returns a paginated list" do
    Reservation.delete_all
    Book.delete_all
    15.times { |i| Book.create!(title: "Book #{i}", status: :available) }

    get books_url, params: { per_page: 10, page: 1 }
    assert_response :success

    body = JSON.parse(@response.body)
    assert_equal 10, body.size
    assert_equal "15", @response.headers["X-Total-Count"]
    assert_equal "2",  @response.headers["X-Total-Pages"]
  end

  test "GET /books filters by status" do
    Reservation.delete_all
    Book.delete_all
    Book.create!(title: "A", status: :available)
    Book.create!(title: "B", status: :reserved)
    Book.create!(title: "C", status: :reserved)

    get books_url, params: { status: "reserved" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 2, body.size
    assert(body.all? { |b| b["status"] == "reserved" })
  end

  test "GET /books does not trigger N+1 for reservations_count" do
    Reservation.delete_all
    Book.delete_all
    books = 5.times.map { |i| Book.create!(title: "B#{i}", status: :available) }
    books.each { |b| b.reservations.create!(email: "x@y.com") }

    queries = 0
    counter = ->(_n, _s, _f, _id, payload) {
      queries += 1 unless payload[:name] == "SCHEMA" || payload[:sql] =~ /TRANSACTION|SAVEPOINT/
    }

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
      get books_url
    end

    assert_response :success
    # Without counter cache this would scale with the number of books.
    # We just assert it's a small constant set of queries.
    assert queries < 6, "Expected a small constant number of queries, got #{queries}"
  end

  # ---------- show ----------
  test "GET /books/:id returns the book with its reservations" do
    book = Book.create!(title: "Showable", status: :available)
    book.reservations.create!(email: "a@example.com")
    book.reservations.create!(email: "b@example.com")

    get book_url(book)
    assert_response :success

    body = JSON.parse(@response.body)
    assert_equal book.id, body["id"]
    assert_equal 2, body["reservations"].size
  end

  test "GET /books/:id returns 404 when not found" do
    get book_url(id: 0)
    assert_response :not_found
  end

  test "GET /books/:id sets ETag for caching" do
    book = Book.create!(title: "Cacheable", status: :available)

    get book_url(book)
    assert_response :success
    assert @response.headers["ETag"].present?

    # second request with matching If-None-Match should return 304
    get book_url(book), headers: { "If-None-Match" => @response.headers["ETag"] }
    assert_response :not_modified
  end
end
