require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../book_spec_helper.rb"


describe BookBook do
  include BookSpecHelper

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :end_users

  def book(title)
    BookBook.create(:name => title)
  end

  describe "basics" do
    it "should require a name" do
      @book = BookBook.new
      @book.should have(1).error_on(:name)
    end

    it "should automatically create a root node" do
      assert_difference 'BookBook.count', 1 do
        assert_difference 'BookPage.count', 1 do
          @book = book("test book 1")
          @book.root_node.should_not be_nil
        end 
      end 
    end

    it "should create a root node for chapter books only" do
      @book = BookBook.new :name => 'chapter'
      @book.save

      assert_difference 'BookPage.count', 1 do
        @book.root_node
      end

      @book = BookBook.new :name => 'flat'
      @book.book_type = 'flat'
      @book.save

      assert_difference 'BookPage.count', 0 do
        @book.root_node
      end
    end

    it "should be able to get the first page of a book" do
      chapter_book
      @cb.first_page.id.should == @page1.id

      flat_book
      @flatbook.first_page.id.should == @flatpage1.id
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
      @book.book_pages.create(:name => 'new_page')
      @book.book_pages.create(:name => 'newer_page')

      @df = DomainFile.create(:filename => book_fixture_file_upload("files/book-import.csv"))
    end

    it 'should parse an insert/update rows of csv' do

      @book.book_pages.create(:name => 'duck', :body => 'duck of many')

      assert_difference 'BookPage.count', 5 do
        @book.import_book(@df.filename,@myself)
      end

      @book.book_pages.find_by_name('goose').should_not be_nil

      @duck = @book.book_pages.find_by_name('duck')
      @duck1 = @book.book_pages.find_by_name('duck1')
      @duck1.parent_id.should == @duck.id
      @duck.body.should == 'of'
    end
  end
end


