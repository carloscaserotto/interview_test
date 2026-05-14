require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
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

  test "GET /books returns the list of books" do
    get books_url
    assert_response :success
  end

  test "GET /books filters by status" do
    Reservation.delete_all
    Book.delete_all
    Book.create!(title: "A", status: :available)
    Book.create!(title: "B", status: :reserved)

    get books_url, params: { status: "reserved" }
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal 1, body.size
    assert_equal "reserved", body.first["status"]
  end

  test "GET /books/:id returns the book" do
    book = Book.create!(title: "Showable", status: :available)

    get book_url(book)
    assert_response :success
    body = JSON.parse(@response.body)
    assert_equal book.id, body["id"]
  end

  test "GET /books/:id returns 404 when not found" do
    get book_url(id: 0)
    assert_response :not_found
  end
end
