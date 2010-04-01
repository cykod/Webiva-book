require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../book_spec_helper.rb"


describe BookBook do
  include BookSpecHelper

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :end_users
  before(:each) do 
    mock_editor
    def book(title)
      BookBook.create(:name => title,:created_by_id => @myself.id)
    end 
    @book1 = book("book basic")
  end
  describe "basics" do
    specify { @book1.should be_valid }

    it "should automatically create a root node" do
      assert_difference 'BookBook.count', 1 do
        assert_difference 'BookPage.count', 1 do
          @book = book("test book 1")
          @book.root_node.should_not be_nil
        end 
      end 
    end
  end
  describe "exports" do
    before(:each) do
      @book = book("test export")
      @export = @book.export_book('csv')
      @file_loc = "#{RAILS_ROOT}/tmp/export/"
      @files = Dir.entries(@file_loc).detect {|f| f.match /book_export/}
    end
    after(:each) do
      File.delete("#{@file_loc}/#{@files}")
    end
    it "should create an exported book" do
      @files.should == "domain:#{DomainModel.active_domain_id.to_s}-book:#{@book.id}_book_export"
      @export.should_not be_nil
    end
    it "exported book should not contain root pages" do
      @export_contents = IO.read("#{RAILS_ROOT}/tmp/export/#{@files}").grep(/Root/)
      @export_contents.should == []
    end
  end
  describe 'imports' do
    before(:each) do
      @book = book("test import")
      @book.book_pages.create(:name => 'new_page',:created_by_id => @myself.id)
      @book.book_pages.create(:name => 'newer_page',:created_by_id => @myself.id)

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
      @book.parse_csv(@df.filename,@myself.id)    
      @count = @book.book_pages.maximum('id')
      @book.book_pages.find_by_name('goose').id.should == @count

    end
    it 'should parse an update id row of csv' do
      # ID 4 matches the import file 
      @book.parse_csv(@df.filename,@myself.id)
      @book.book_pages.find_by_id(5).name.should == 'chapter one'
      @book.book_pages.find_by_id(5).body.should == 'tons'

    end
    it 'should parse an update name row of csv' do
      @book.parse_csv(@df.filename,@myself.id)
      @book.book_pages.find_by_name('duck') 
    end
    it 'should parse an entire file' do 
      @pre_ins_page_count = @book.book_pages.count(:conditions => ["name != ?", "Root"])
      csv_data = CSV.read @df.filename
      headers = csv_data.shift.map {|i| i.to_s }
      import_data = csv_data.map {|row| row.map {|cell| cell.to_s } }

      @new_page_count = 0
      import_data.each {|row| @new_page_count +=1 if row[0] = ""}


      @pre_ins = @book.book_pages.count
      @book.do_import(@df.filename,@myself.id)
      @ins = @book.book_pages.count
      @ins.should == @pre_ins_page_count+@new_page_count

    end
  end


end


