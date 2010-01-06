class WikiStatus < ActiveRecord::Migration
  def self.up
    add_column :book_page_versions, :status, :string, :size => 20
    add_column :book_page_versions, :version_type, :string, :size => 20
    add_index :book_page_versions, :status, :name => 'status_index'
  end

  def self.down
    remove_column :book_page_versions, :status
    remove_column :book_page_versions, :version_type
    remove_index :book_page_versions, :name => 'status_index'
  end
end
