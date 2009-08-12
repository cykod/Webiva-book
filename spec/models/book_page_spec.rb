require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"


describe BookPage do
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions


  it "should be able to add pages to a book" do

    @book = BookBook.create(:name => 'book')

    @book.root_node.should_not be_nil

    @page = @book.book_pages.create(:name => 'Test Page')
    @page.move_to_child_of(@book.root_node)

    @page.parent_id.should == @book.root_node.id
  end

end
  
