require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"
require  File.expand_path(File.dirname(__FILE__)) + "/../../book_spec_helper.rb"

describe Book::PageRenderer, :type => :controller do
  include BookSpecHelper
  controller_name :page

  integrate_views

  reset_domain_tables :book_books, :book_pages, :book_page_versions, :page_paragraphs, :site_nodes, :end_users
  
  def root_page
    @root_page ||= SiteVersion.default.root.add_subpage('book')
  end

  def edit_page
    @edit_page ||= SiteVersion.default.root.add_subpage('edit')
  end

  def generate_page_renderer(paragraph, options={}, inputs={})
    @rnd = build_renderer('/page', '/book/page/' + paragraph, options, inputs)
    @rnd.should_receive(:site_node).any_number_of_times.and_return(root_page) if paragraph == 'content'
    @rnd
  end

  describe 'Chapters Paragraph' do
    describe 'Chapter Book' do
      before(:each) do
        @book = chapter_book
      end

      it 'should raise page not found if missing book' do
        @book.book_type.should == 'chapter'
        @book.url_scheme.should == 'flat'
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should find a book by page connection' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id}, {:book => [:book_id, @book.id]})
        renderer_get @rnd
      end

      it 'should find a book by input' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id})
        renderer_get @rnd
      end

      it 'should mark page as selected' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page1.url]})
        @rnd.should_render_feature :menu
        renderer_get @rnd
        @rnd.renderer_feature_data[:menu][0][:selected].should be_true
        @rnd.renderer_feature_data[:menu][1][:selected].should be_false
      end

      it 'should not care if page is not found' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, 'invalid url']})
        @rnd.should_render_feature :menu
        renderer_get @rnd
        @rnd.renderer_feature_data[:menu][0][:selected].should be_false
        @rnd.renderer_feature_data[:menu][1][:selected].should be_false
      end

      it 'should not include unpublished pages in menu' do
        @page2.update_attribute :published, false
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id})
        @rnd.should_render_feature :menu
        renderer_get @rnd

        @rnd.renderer_feature_data[:menu].find { |link| link[:title] == @page1.name }.should_not be_nil

        @rnd.renderer_feature_data[:menu].each do |link|
          link[:title].should_not == @page2.name
        end
      end
    end

    describe 'Chapter Book using ids' do
      before(:each) do
        @book = chapter_book 'id'
      end

      it 'should raise page not found if missing book' do
        @book.book_type.should == 'chapter'
        @book.url_scheme.should == 'id'
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should find a book by page connection' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id}, {:book => [:book_id, @book.id]})
        renderer_get @rnd
      end

      it 'should find a book by input' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id})
        renderer_get @rnd
      end

      it 'should mark page as selected' do
        @page1.id.to_s.should == @page1.url
        @page1.path.to_s.should == "/#{@page1.url}"
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page1.url]})
        @rnd.should_render_feature :menu
        renderer_get @rnd
        @rnd.renderer_feature_data[:menu][0][:selected].should be_true
        @rnd.renderer_feature_data[:menu][1][:selected].should be_false
      end

      it 'should not care if page is not found' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, 'invalid url']})
        @rnd.should_render_feature :menu
        renderer_get @rnd
        @rnd.renderer_feature_data[:menu][0][:selected].should be_false
        @rnd.renderer_feature_data[:menu][1][:selected].should be_false
      end

      it 'should not include unpublished pages in menu' do
        @page2.update_attribute :published, false
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id})
        @rnd.should_render_feature :menu
        renderer_get @rnd

        @rnd.renderer_feature_data[:menu].find { |link| link[:title] == @page1.name }.should_not be_nil

        @rnd.renderer_feature_data[:menu].each do |link|
          link[:title].should_not == @page2.name
        end
      end
    end

    describe 'Chapter Book using nested' do
      before(:each) do
        @book = chapter_book 'nested'
      end

      it 'should raise page not found if missing book' do
        @book.book_type.should == 'chapter'
        @book.url_scheme.should == 'nested'
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found because it is a nested url book' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id}, {:book => [:book_id, @book.id]})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end
    end

    describe 'Flat Book' do
      before(:each) do
        @book = flat_book
        @page1 = @book.book_pages[0]
        @page2 = @book.book_pages[1]
      end

      it 'should raise page not found if missing book' do
        @book.book_type.should == 'flat'
        @book.url_scheme.should == 'flat'
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should find a book by page connection' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id}, {:book => [:book_id, @book.id]})
        renderer_get @rnd
      end

      it 'should find a book by input' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id})
        renderer_get @rnd
      end

      it 'should mark page as selected' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page1.url]})
        @rnd.should_render_feature :menu
        renderer_get @rnd
        @rnd.renderer_feature_data[:menu][0][:selected].should be_true
        @rnd.renderer_feature_data[:menu][1][:selected].should be_false
      end

      it 'should not care if page is not found' do
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, 'invalid url']})
        @rnd.should_render_feature :menu
        renderer_get @rnd
        @rnd.renderer_feature_data[:menu][0][:selected].should be_false
        @rnd.renderer_feature_data[:menu][1][:selected].should be_false
      end

      it 'should not include unpublished pages in menu' do
        @page2.update_attribute :published, false
        @rnd = generate_page_renderer('chapters', {:root_page_id => root_page.id, :book_id => @book.id})
        @rnd.should_render_feature :menu
        renderer_get @rnd

        @rnd.renderer_feature_data[:menu].find { |link| link[:title] == @page1.name }.should_not be_nil

        @rnd.renderer_feature_data[:menu].each do |link|
          link[:title].should_not == @page2.name
        end
      end
    end
  end

  describe 'Content Paragraph' do
    describe 'Chapter Book' do
      before(:each) do
        @book = chapter_book
      end

      it 'should raise page not found if missing book' do
        @rnd = generate_page_renderer('content')
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found if page is missing' do
        @rnd = generate_page_renderer('content', {}, {:book => [:book_id, @book.id]})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found if page is missing' do
        @rnd = generate_page_renderer('content', {:book_id => @book.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found if page is not published' do
        @page2.update_attribute :published, false
        @rnd = generate_page_renderer('content', {:book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should display first page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true}, {:book => [:book_id, @book.id]})
        renderer_get @rnd
      end

      it 'should display first page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :book_id => @book.id})
        renderer_get @rnd
      end

      it 'should display page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        renderer_get @rnd
        response.body.should include(@page2.name)
      end

      it 'should display page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :book_id => @book.id})
        renderer_get @rnd, :ref => @page2.reference
        response.body.should include(@page2.name)
      end

      it 'should display create page' do
        @rnd = generate_page_renderer('content', {:enable_wiki => true, :edit_page_id => edit_page.id, :book_id => @book.id})
        renderer_get @rnd
        response.body.should include(edit_page.node_path)
      end

      it 'should display edit page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :enable_wiki => true, :edit_page_id => edit_page.id, :book_id => @book.id})
        renderer_get @rnd
        response.body.should include("#{edit_page.node_path}#{@page1.path}")
      end

      it 'should display edit page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :enable_wiki => true, :edit_page_id => edit_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        renderer_get @rnd
        response.body.should include("#{edit_page.node_path}#{@page2.path}")
      end

      it 'should not display edit page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :enable_wiki => false, :edit_page_id => edit_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        renderer_get @rnd
        response.body.should_not include("#{edit_page.node_path}#{@page2.path}")
      end

      it 'should not display edit page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :enable_wiki => true, :edit_page_id => nil, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        renderer_get @rnd
        response.body.should_not include("#{edit_page.node_path}#{@page2.path}")
      end
    end

    describe 'Content Book using nested' do
      before(:each) do
        @book = chapter_book 'nested'
      end

      it 'should raise page not found because it is a nested url book' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :book_id => @book.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end
    end

    describe 'Flat Book' do
      before(:each) do
        @book = flat_book
        @page1 = @book.book_pages[0]
        @page2 = @book.book_pages[1]
      end

      it 'should display first page' do
        @rnd = generate_page_renderer('content', {:show_first_page => true, :book_id => @book.id})
        renderer_get @rnd
      end
    end
  end

  describe 'Wiki Editor Paragraph' do
    describe 'Chapter Book' do
      before(:each) do
        @book = chapter_book
      end

      it 'should raise page not found if missing book' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found if page is missing' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id}, {:book => [:book_id, @book.id]})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found if page is missing' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :book_id => @book.id})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should raise page not found if page is not published' do
        @page2.update_attribute :published, false
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        lambda { renderer_get @rnd }.should raise_error(SiteNodeEngine::MissingPageException)
      end

      it 'should display create page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true}, {:book => [:book_id, @book.id]})
        renderer_get @rnd
        response.body.should include('page[name]')
        response.body.should include('page[body]')
      end

      it 'should display create page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :book_id => @book.id})
        renderer_get @rnd
        response.body.should include('page[name]')
        response.body.should include('page[body]')
      end

      it 'should display create page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :book_id => @book.id}, {:flat_chapter => [:chapter_id, 'missing-page-name']})
        renderer_get @rnd
        response.body.should include('page[name]')
        response.body.should include('Missing Page Name')
        response.body.should include('page[body]')
      end

      it 'should display edit page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        renderer_get @rnd
        response.body.should_not include('page[name]')
        response.body.should include('page[body]')
      end

      it 'should create a page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :book_id => @book.id})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 1 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.last
        @version = @page.book_page_versions.last
        @version.version_status.should == 'submitted'
        @version.version_type.should == 'wiki'
        @page.url.should == 'my-new-page'
        @page.path.should == '/my-new-page'
        @page.name.should == 'My New Page'
        @page.body.should == 'My New Body'
        @page.published.should be_false

        @rnd.should redirect_paragraph(root_page.node_path)
      end

      it 'should create a page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :book_id => @book.id}, {:flat_chapter => [:chapter_id, 'new-page2']})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 1 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.last
        @version = @page.book_page_versions.last
        @version.version_status.should == 'submitted'
        @version.version_type.should == 'wiki'
        @page.name.should == 'My New Page'
        @page.body.should == 'My New Body'
        @page.published.should be_false
        @page.url.should == 'new-page2'
        @page.path.should == '/new-page2'

        @rnd.should redirect_paragraph(root_page.node_path)
      end

      it 'should create a page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :allow_auto_version => true, :book_id => @book.id}, {:flat_chapter => [:chapter_id, 'new-page2']})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 1 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.last
        @version = @page.book_page_versions.last
        @version.version_status.should == 'accepted wiki'
        @version.version_type.should == 'wiki_auto_publish'
        @page.name.should == 'My New Page'
        @page.body.should == 'My New Body'
        @page.published.should be_true
        @page.url.should == 'new-page2'
        @page.path.should == '/new-page2'

        @rnd.should redirect_paragraph("#{root_page.node_path}#{@page.path}")
      end

      it 'should create a page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :allow_auto_version => true, :book_id => @book.id})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 1 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.last
        @version = @page.book_page_versions.last
        @version.version_status.should == 'accepted wiki'
        @version.version_type.should == 'wiki_auto_publish'
        @page.name.should == 'My New Page'
        @page.body.should == 'My New Body'
        @page.published.should be_true

        @rnd.should redirect_paragraph("#{root_page.node_path}#{@page.path}")
      end

      it 'should create a page' do
        mock_user

        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_create => true, :allow_auto_version => true, :book_id => @book.id})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 1 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.last
        @version = @page.book_page_versions.last
        @version.version_status.should == 'accepted wiki'
        @version.version_type.should == 'wiki_auto_publish'
        @version.created_by_id.should == @myself.id
        @page.name.should == 'My New Page'
        @page.body.should == 'My New Body'
        @page.published.should be_true
        @page.created_by_id.should == @myself.id
        @page.updated_by_id.should == @myself.id

        @rnd.should redirect_paragraph("#{root_page.node_path}#{@page.path}")
      end

      it 'should edit a page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 0 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.find @page2.id
        @version = @page.book_page_versions.last
        @version.version_status.should == 'submitted'
        @version.version_type.should == 'wiki'
        @version.name.should_not == 'My New Page'
        @version.body.should == 'My New Body'
        @page.name.should_not == 'My New Page'
        @page.body.should_not == 'My New Body'
        @page.published.should be_true

        @rnd.should redirect_paragraph("#{root_page.node_path}#{@page.path}")
      end

      it 'should edit a page' do
        @rnd = generate_page_renderer('wiki_editor', {:root_page_id => root_page.id, :allow_auto_version => true, :book_id => @book.id}, {:flat_chapter => [:chapter_id, @page2.url]})
        assert_difference 'BookPageVersion.count', 1 do
          assert_difference 'BookPage.count', 0 do
            renderer_post @rnd, :commit => 'Submit', :page => {:name => 'My New Page', :body => 'My New Body'}
          end
        end

        @page = BookPage.find @page2.id
        @version = @page.book_page_versions.last
        @version.version_status.should == 'accepted wiki'
        @version.version_type.should == 'wiki_auto_publish'
        @version.name.should_not == 'My New Page'
        @version.body.should == 'My New Body'
        @page.name.should_not == 'My New Page'
        @page.body.should == 'My New Body'
        @page.published.should be_true

        @rnd.should redirect_paragraph("#{root_page.node_path}#{@page.path}")
      end
    end
  end
end
