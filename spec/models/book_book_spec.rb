require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"


describe BookBook do
  
  reset_domain_tables :book_books, :book_pages, :book_page_versions

  it "should automatically create a root node" do

    BookBook.count.should == 0
    BookPage.count.should == 0
    @book = BookBook.create(:name => 'book')
    
    BookBook.count.should == 1
    BookPage.count.should == 1
    @book.root_node.should_not be_nil

  end

 
end
  
