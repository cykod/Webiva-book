require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../book_spec_helper.rb"


describe BookBook do
      include BookSpecHelper

  reset_domain_tables :book_books, :book_pages, :book_page_versions

  it "should automatically create a root node" do

    BookBook.count.should == 0
    BookPage.count.should == 0
    @book = BookBook.create(:name => 'book',:created_by_id => 1)
    
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
 
  
 
  describe 'imports' do
    before(:each) do
      @book = BookBook.create(:name => 'book')
      @book.book_pages.create(:name => 'new_page')
      @book.book_pages.create(:name => 'newer_page')
      
      @folder = DomainFile.create_folder("My Folder")
      @folder.save
      fdata = book_fixture_file_upload("files/book-import.csv")
      @df = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
      fdata = book_fixture_file_upload("files/book-import2.csv")
      @df2 = DomainFile.create(:filename => fdata,:parent_id => @folder.id)
    end
    
    it 'should return true on header match' do
      @book.check_header(@df.filename).should be_true     
    end
    it 'should return false on header fail' do
      @book.check_header(@df2.filename).should be_false     
    end
    
    it 'should parse an insert row of csv' do
      @book.parse_csv(@df.filename)    
      @count = @book.book_pages.maximum('id')
      @book.book_pages.find_by_name('goose').id.should == @count
      
    end
    it 'should parse an update id row of csv' do
      # ID 4 matches the import file 
      @book.parse_csv(@df.filename)
      @page_gook = @book.book_pages(:all)
      @book.book_pages.find_by_id(4).name.should == 'chapter one'
      @book.book_pages.find_by_id(4).body.should == 'tons'

    end
    it 'should parse an update name row of csv' do
      @book.parse_csv(@df.filename)
      raise @page2.id.inspect
      @book.book_pages.find_by_id(@page4.id).name.should == 'duck'
    end
    it 'should parse an entire file' do 
      @pre_ins_page_count = @book.book_pages.count(:conditions => ["name != ?", "Root"])
      csv_data = CSV.read @df.filename
      headers = csv_data.shift.map {|i| i.to_s }
      import_data = csv_data.map {|row| row.map {|cell| cell.to_s } }

      @new_page_count = 0
      import_data.each {|row| @new_page_count +=1 if row[0] = ""}
       
      
      @pre_ins = @book.book_pages.count
      @book.do_import(@df.filename)
      @ins = @book.book_pages.count
      @ins.should == @pre_ins_page_count+@new_page_count
      
    end
  end
  
  
end


