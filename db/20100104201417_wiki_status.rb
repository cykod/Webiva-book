class WikiStatus < ActiveRecord::Migration
  def self.up
    add_column :book_page_versions, :version_status, :string, :size => 20
    add_column :book_page_versions, :version_type, :string, :size => 20
    add_column :book_page_versions, :ipaddress, :string, :size => 15
    add_index :book_page_versions, :version_status, :name => 'status_index'
  end

  def self.down
    remove_column :book_page_versions, :version_status
    remove_column :book_page_versions, :version_type
    remove_column :book_page_versions, :ipaddress
    remove_index :book_page_versions, :name => 'status_index'
  end
end
