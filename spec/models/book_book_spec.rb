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
  it "should create an exported book" do
    @book = BookBook.create(:name => 'book')
    @book.export_book('csv').should_not be_nil
    @filename = Dir.entries("#{RAILS_ROOT}/tmp/export/").detect {|f| f.match /book_export/}
    @filename.should == '1_book_export'
    
  end
  it "should not contain root pages" do
     @book = BookBook.create(:name => 'book')
    @book.book_pages.create(:name => 'new_page')
    @filename = Dir.entries("#{RAILS_ROOT}/tmp/export/").detect {|f| f.match /book_export/}
    @export_contents = IO.read("#{RAILS_ROOT}/tmp/export/#{@filename}").grep(/Root/)
    
    @export_contents.should == []
  end
 
end
  
