# Copyright (C) 2010 Cykod LLC.


require  File.expand_path(File.dirname(__FILE__)) + "/../../../../../spec/spec_helper"


describe BookWizardController do

  before(:each) do
    @book = BookBook.new(:name => "Test Auto Create Book")
  end
  

  it 'should redirect to main wizards form from index' do
            post( 'index', :path => [], :controller => '/book/wizard')
    
  end

  it 'should redirect to structure on successful add' do
  end

end
