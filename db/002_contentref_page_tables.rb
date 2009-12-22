class ContentrefPageTables < ActiveRecord::Migration
  def self.up
    add_column :book_pages, :reference, :string
    add_index :book_pages, :reference, :name => 'reference_index'
  end

  def self.down
    remove_column :book_pages, :reference
    drop_index :book_pages, :name => 'reference_index'
    
  end
end
