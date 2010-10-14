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
      @file_loc = "#{RAILS_ROOT}/tmp/export"
      @book = book("test export")

      Dir.entries(@file_loc).detect {|f| File.delete("#{@file_loc}/#{f}") if f.match /book_export/}

      @export = @book.export_book('csv')
      @files = Dir.entries(@file_loc).detect {|f| f.match /book_export/}
    end

    after(:each) do
      File.delete("#{@file_loc}/#{@files}")
    end

    it "should create an exported book" do
      @files.should == "#{DomainModel.active_domain_id.to_s}_book_export.csv"
      @export.should_not be_nil
    end

    it "exported book should not contain root pages" do
      @export_contents = IO.read("#{@file_loc}/#{@files}").grep(/Root/)
      @export_contents.should == []
    end
  end

  describe 'imports' do
    before(:each) do
      @book = book("test import")
      @book.book_pages.create(:name => 'new_page', :created_by_id => @myself.id)
      @book.book_pages.create(:name => 'newer_page', :created_by_id => @myself.id)

      fdata = book_fixture_file_upload("files/book-import.csv")
      @df = DomainFile.create(:filename => fdata)
      fdata = book_fixture_file_upload("files/book-import2.csv")
      @df2 = DomainFile.create(:filename => fdata)
    end

    it 'should parse an insert row of csv' do
      assert_difference 'BookPage.count', 6 do
        @book.import_book(@df.filename,@myself)
        @book.book_pages.find_by_name('goose').should_not be_nil
      end
    end
  end
end


