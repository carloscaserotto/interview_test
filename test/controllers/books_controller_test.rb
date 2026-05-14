require "test_helper"

class BooksControllerTest < ActionDispatch::IntegrationTest
    test "should reserve book with valid email" do
        book = Book.create!(title: "Test Book 101", status: :available)

        post reserve_book_url(book), params: { reservation: { email: "test@example.com" } }
        assert_response :created   

        assert_equal "reserved", book.reload.status
    end
end