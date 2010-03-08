# Copyright (C) 2010 Cykod LLC.

require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../../spec/spec_helper"



describe Book::WizardController do

  before(:each) do
    mock_editor
    @book = BookBook.new(:name => "Test Auto Create Book")
  end
  

  it 'should redirect to main wizards from form index' do
    post( 'index', :path => [1], :controller => '/book/wizard')
    response.should redirect_to(:controller => '/structure', :action => 'wizards')

    
  end

  it 'should redirect to structure on successful add' do
    post( 'index', :path => [1], :commit => 'Add to Site',:controller => '/book/wizard', :wizard => {:opts => [""], :add_to_subpage => "asdf", :wiki_page_url => "edit", :add_to_id =>4, :add_to_existing => "", :book_id =>1})
    response.should redirect_to(:controller => '/structure')







  end

end
